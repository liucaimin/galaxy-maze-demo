import dotenv from 'dotenv'
import express from 'express'
import mysql from 'mysql2/promise'
import { randomUUID } from 'node:crypto'

dotenv.config({ path: '.env.server.local' })

const requiredEnvironment = [
  'DB_HOST',
  'DB_USER',
  'DB_PASSWORD',
  'DB_NAME',
  'APP_USER_NAME',
  'APP_USER_PASSWORD',
  'APP_ADMIN_NAME',
  'APP_ADMIN_PASSWORD',
]
const missingEnvironment = requiredEnvironment.filter((key) => !process.env[key])

if (missingEnvironment.length) {
  console.error(`数据库配置缺失：${missingEnvironment.join(', ')}。请填写 .env.server.local。`)
  process.exit(1)
}

const app = express()
const port = Number(process.env.API_PORT || 3001)
const totalLevels = 36

app.use(express.json({ limit: '20kb' }))

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 5,
  queueLimit: 0,
  charset: 'utf8mb4',
})

const answerFields = [
  'has_galaxy',
  'one_dominant',
  'components_overlap',
  'is_elliptical',
  'is_edge_on',
  'has_bulge',
  'has_bar',
  'has_spiral_arms',
  'has_ring',
  'has_dust_lane',
  'has_lens_multiple',
  'has_lens_arc',
  'has_special',
]

const allowedAnswers = new Set(['是', '否', '未选择'])
const sessions = new Map()
const accounts = {
  user: {
    username: process.env.APP_USER_NAME,
    password: process.env.APP_USER_PASSWORD,
    role: 'user',
    displayName: '星系探索员',
  },
  admin: {
    username: process.env.APP_ADMIN_NAME,
    password: process.env.APP_ADMIN_PASSWORD,
    role: 'admin',
    displayName: '标定管理员',
  },
}

const getSession = (request) => {
  const authorization = request.get('authorization') || ''
  const token = authorization.startsWith('Bearer ') ? authorization.slice(7) : ''
  return token ? { token, session: sessions.get(token) } : null
}

const requireRole = (role) => (request, response, next) => {
  const authentication = getSession(request)
  if (!authentication?.session || authentication.session.role !== role) {
    return response.status(401).json({ message: '登录状态无效或没有操作权限' })
  }
  request.authentication = authentication
  next()
}

app.post('/api/auth/login', (request, response) => {
  const username = String(request.body?.username || '').trim()
  const password = String(request.body?.password || '')
  const account = Object.values(accounts).find(
    (candidate) => candidate.username === username && candidate.password === password,
  )

  if (!account) return response.status(401).json({ message: '账号或密码不正确' })

  const token = randomUUID()
  const session = { role: account.role, displayName: account.displayName }
  sessions.set(token, session)
  response.json({ token, ...session })
})

app.get('/api/auth/me', (request, response) => {
  const authentication = getSession(request)
  if (!authentication?.session) return response.status(401).json({ message: '登录已失效' })
  response.json(authentication.session)
})

app.post('/api/auth/logout', (request, response) => {
  const authentication = getSession(request)
  if (authentication) sessions.delete(authentication.token)
  response.status(204).end()
})

app.get('/api/health', async (_request, response) => {
  try {
    const [rows] = await pool.execute('SELECT COUNT(*) AS levelCount FROM galaxy_levels')
    response.json({ ok: true, levelCount: Number(rows[0].levelCount) })
  } catch (error) {
    console.error(error)
    response.status(503).json({ ok: false, message: '无法连接数据库或读取关卡表' })
  }
})

app.get('/api/levels', async (_request, response) => {
  try {
    const [rows] = await pool.execute(
      `SELECT
         id,
         galaxy_name AS galaxyName,
         image_path AS imagePath
       FROM galaxy_levels
       ORDER BY id`,
    )
    response.json({ levels: rows })
  } catch (error) {
    console.error(error)
    response.status(500).json({ message: '读取星系名称失败' })
  }
})

app.get('/api/admin/levels', requireRole('admin'), async (_request, response) => {
  try {
    const [rows] = await pool.execute(
      `SELECT
         id,
         galaxy_name AS galaxyName,
         image_path AS imagePath,
         ${answerFields.join(', ')}
       FROM galaxy_levels
       ORDER BY id`,
    )
    response.json({ levels: rows })
  } catch (error) {
    console.error(error)
    response.status(500).json({ message: '读取管理员关卡数据失败' })
  }
})

app.put('/api/admin/levels/:id/answers', requireRole('admin'), async (request, response) => {
  try {
    const levelId = Number(request.params.id)
    const submitted = request.body?.answers

    if (!Number.isInteger(levelId) || levelId < 1 || levelId > totalLevels) {
      return response.status(400).json({ message: '无效的关卡编号' })
    }

    if (
      !submitted ||
      typeof submitted !== 'object' ||
      Array.isArray(submitted) ||
      answerFields.some((field) => !allowedAnswers.has(submitted[field]))
    ) {
      return response.status(400).json({ message: '必须提交全部13个有效属性答案' })
    }

    const values = answerFields.map((field) => submitted[field])
    const assignments = answerFields.map((field) => `${field} = ?`).join(', ')
    const [result] = await pool.execute(
      `UPDATE galaxy_levels SET ${assignments} WHERE id = ?`,
      [...values, levelId],
    )

    if (result.affectedRows === 0) {
      return response.status(404).json({ message: '数据库中不存在该关卡' })
    }

    response.json({ saved: true, id: levelId, answers: submitted })
  } catch (error) {
    console.error(error)
    if (error?.code === 'ER_TABLEACCESS_DENIED_ERROR') {
      return response.status(403).json({ message: '数据库账号 galaxy_game 暂无 UPDATE 权限，请先授权后再保存' })
    }
    response.status(500).json({ message: '保存标定答案失败' })
  }
})

app.post('/api/levels/:id/check', async (request, response) => {
  try {
    const levelId = Number(request.params.id)
    const submitted = request.body?.answers

    if (!Number.isInteger(levelId) || levelId < 1 || levelId > totalLevels) {
      return response.status(400).json({ message: '无效的关卡编号' })
    }

    if (
      !submitted ||
      typeof submitted !== 'object' ||
      Array.isArray(submitted) ||
      answerFields.some((field) => !allowedAnswers.has(submitted[field]))
    ) {
      return response.status(400).json({ message: '必须提交全部13个有效属性答案' })
    }

    const [rows] = await pool.execute(
      `SELECT ${answerFields.join(', ')} FROM galaxy_levels WHERE id = ?`,
      [levelId],
    )

    if (rows.length === 0) {
      return response.status(404).json({ message: '该关卡尚未在数据库中标定' })
    }

    const standard = rows[0]
    const answeredFields = answerFields.filter((field) => submitted[field] !== '未选择')
    const correctCount = answeredFields.filter((field) => submitted[field] === standard[field]).length
    const correct = answerFields.every((field) => submitted[field] === standard[field])

    return response.json({ correct, correctCount, answeredCount: answeredFields.length })
  } catch (error) {
    console.error(error)
    return response.status(500).json({ message: '数据库判题失败' })
  }
})

app.listen(port, '127.0.0.1', () => {
  console.log(`判题服务运行于 http://127.0.0.1:${port}`)
})
