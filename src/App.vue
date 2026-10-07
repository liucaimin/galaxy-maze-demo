<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import smoothExample from './assets/images/examples/example-smooth.png'
import edgeExample from './assets/images/examples/example-edge-on.png'
import barredExample from './assets/images/examples/example-barred.png'
import armsExample from './assets/images/examples/example-spiral-arms.png'
import decisionTreeImage from './assets/images/guide/galaxy-decision-tree.svg'

const levelImageModules = import.meta.glob('./assets/images/levels/*.{png,jpg,jpeg,webp}', {
  eager: true,
  query: '?url',
  import: 'default',
}) as Record<string, string>

const exampleImageModules = import.meta.glob('./assets/images/examples/*.{png,jpg,jpeg,webp}', {
  eager: true,
  query: '?url',
  import: 'default',
}) as Record<string, string>

const puzzleImageModules = import.meta.glob('./assets/images/puzzle/*.{png,jpg,jpeg,webp}', {
  eager: true,
  query: '?url',
  import: 'default',
}) as Record<string, string>

const levelImagesByFilename = Object.fromEntries(
  Object.entries(levelImageModules).map(([path, source]) => [path.split('/').pop()!, source]),
)
const availableLevelImages = Object.values(levelImagesByFilename)
const exampleImagesByFilename = Object.fromEntries(
  Object.entries(exampleImageModules).map(([path, source]) => [path.split('/').pop()!, source]),
)
const namedExample = (filename: string, fallback: string) => exampleImagesByFilename[filename] || fallback
const level01Image = levelImagesByFilename['level-01.png'] || availableLevelImages[0] || armsExample
const level02Image = levelImagesByFilename['level-02.png'] || availableLevelImages[1] || smoothExample

type AnswerValue = 'yes' | 'no'
type AnswerOption = { value: AnswerValue; label: string; detail: string }
type Example = { title: string; image: string; note: string }
type Question = { id: string; short: string; title: string; question: string; hint: string; options: AnswerOption[]; examples: Example[] }
type Level = {
  id: number; catalog: string; title: string; image: string
  ra: string; dec: string; redshift: string; magnitude: string; clue: string; science: string
}
type HistoryStep = { nodeId: string; value: AnswerValue; label: string }
type Direction = 'up' | 'right' | 'down' | 'left'
type Cell = { row: number; col: number; walls: Record<Direction, boolean> }
type AnsweredCell = { nodeId: string; label: string; value: AnswerValue }
type DatabaseAnswer = '是' | '否' | '未选择'
type DatabaseAnswerField = 'has_galaxy' | 'one_dominant' | 'components_overlap' | 'is_elliptical' | 'is_edge_on' | 'has_bulge' | 'has_bar' | 'has_spiral_arms' | 'has_ring' | 'has_dust_lane' | 'has_lens_multiple' | 'has_lens_arc' | 'has_special'
type UserRole = 'user' | 'admin'
type AdminLevel = {
  id: number
  galaxyName: string
  imagePath: string | null
  answers: Record<DatabaseAnswerField, DatabaseAnswer>
}
type PuzzleDefinition = { id: string; name: string; image: string }
type LevelOutcome = {
  correct: boolean
  correctCount: number
  answeredCount: number
  earnedPoints: number
  awardedPieces: number
}

const PUZZLE_SIZE = 36
const POINTS_PER_CORRECT = 60
const LEVEL_CLEAR_BONUS = 100
const puzzleSlots = Array.from({ length: PUZZLE_SIZE }, (_, index) => index)
const puzzleCandidates: PuzzleDefinition[] = Object.entries(puzzleImageModules)
  .map(([path, image]) => [path.split('/').pop()!, image] as const)
  .map(([filename, image]) => ({
    id: `puzzle-${filename}`,
    name: filename.replace(/\.(png|jpe?g|webp)$/i, ''),
    image,
  }))

const randomPuzzleCandidate = () => puzzleCandidates[Math.floor(Math.random() * puzzleCandidates.length)]

const answerOptions: AnswerOption[] = [
  { value: 'yes', label: '是', detail: '图像中能看到这一形态特征' },
  { value: 'no', label: '否', detail: '没有看到，或特征明显不符合' },
]

const questions: Record<string, Question> = {
  galaxy: {
    id: 'galaxy', short: '星系图像', title: '确认观测目标', question: '是否包含星系图像？',
    hint: '星系通常呈弥散延展的光斑；单个尖锐亮点、衍射芒或严重裁切目标不适合继续分类。', options: answerOptions,
    examples: [
      { title: '是：包含星系图像', image: namedExample('包含星系图像.png', armsExample), note: '图像中存在可辨认的延展星系结构。' },
      { title: '否：不包含星系图像', image: namedExample('不包含星系图像.png', smoothExample), note: '图像中没有可用于后续形态判断的星系目标。' },
    ],
  },
  dominant: {
    id: 'dominant', short: '主导成分', title: '判断主体数量', question: '是否有一个主导成分？',
    hint: '先找最主要的光分布中心。多个相近亮度的核、桥或潮汐尾可能提示相互作用。', options: answerOptions,
    examples: [
      { title: '是：一个主导成分', image: namedExample('是否有一个主导成分（是）.png', smoothExample), note: '一个主要亮度中心主导整体轮廓。' },
      { title: '否：没有单一主导成分', image: namedExample('是否有一个主导成分（否）.png', barredExample), note: '存在多个需要继续判断的主要成分。' },
    ],
  },
  overlap: {
    id: 'overlap', short: '成分重叠', title: '检查多成分结构', question: '各成分是否有重叠？',
    hint: '留意双核、光桥、拖尾和被拉扯的不对称外轮廓。', options: answerOptions,
    examples: [
      { title: '是：各成分重叠', image: namedExample('各成分是否重叠-Y.png', armsExample), note: '多个成分在图像中的轮廓存在明显交叠。' },
      { title: '否：各成分不重叠', image: namedExample('各成分是否重叠-N.png', edgeExample), note: '各成分彼此分离，没有明显交叠区域。' },
    ],
  },
  elliptical: {
    id: 'elliptical', short: '椭圆星系', title: '检查整体轮廓', question: '是否为椭圆星系？',
    hint: '椭圆星系的亮度从中心向外平滑下降，通常看不到盘面纹理、旋臂和尘埃带。', options: answerOptions,
    examples: [
      { title: '是：椭圆星系', image: namedExample('是否为椭圆星系（是）.png', smoothExample), note: '轮廓连续、亮度渐变平缓，没有可追踪的旋臂。' },
      { title: '否：不是椭圆星系', image: namedExample('是否为椭圆星系（否）.png', armsExample), note: '存在盘面或其他非椭圆形态结构。' },
    ],
  },
  edge: {
    id: 'edge', short: 'Edge-on', title: '判断观测视角', question: '是否为 Edge-on 星系？',
    hint: '侧视盘通常像一条狭长光带，常有贯穿中心的暗尘埃带。', options: answerOptions,
    examples: [
      { title: '是：Edge-on 星系', image: namedExample('是否为edge-on星系-Y.png', edgeExample), note: '盘面接近侧视，整体呈狭长形态。' },
      { title: '否：不是 Edge-on 星系', image: namedExample('是否为edge-on星系-N.png', armsExample), note: '能看到较完整盘面，不属于侧视星系。' },
    ],
  },
  bar: {
    id: 'bar', short: '棒状结构', title: '观察星系中心', question: '核心两侧是否有一条贯穿中心的棒状结构？',
    hint: '棒是近似笔直的亮带，并与两侧盘面相连；不要把单条旋臂当成棒。', options: answerOptions,
    examples: [
      { title: '是：有棒状结构', image: namedExample('是否有棒状结构-Y.png', barredExample), note: '笔直亮带穿过中心，可能与两侧盘面相连。' },
      { title: '否：无棒状结构', image: namedExample('是否有棒状结构-N.png', armsExample), note: '中心没有清晰、连续的棒状亮带。' },
    ],
  },
  arms: {
    id: 'arms', short: '旋臂', title: '追踪盘面纹理', question: '盘面上是否能连续追踪到旋臂？',
    hint: '旋臂是从中心附近向外卷绕的弧线，常带有蓝色结和斑驳尘埃。', options: answerOptions,
    examples: [
      { title: '是：有旋臂结构', image: namedExample('是否有旋臂结构-Y.png', armsExample), note: '至少一条弧状结构能从内向外连续追踪。' },
      { title: '否：无旋臂结构', image: namedExample('是否有旋臂结构-N.png', smoothExample), note: '盘面上没有能够连续追踪的旋臂。' },
    ],
  },
  bulge: {
    id: 'bulge', short: '核球结构', title: '观察中央隆起', question: '是否有核球结构？',
    hint: '核球是盘星系中央较圆、较亮的恒星聚集区。侧视星系中常表现为盘面中央的明显隆起。', options: answerOptions,
    examples: [
      { title: '是：有核球结构', image: namedExample('是否有核球结构-Y.png', edgeExample), note: '中央存在比外盘更亮、更集中的隆起结构。' },
      { title: '否：无核球结构', image: namedExample('是否有核球结构-N.png', barredExample), note: '中央没有能够明确辨认的核球隆起。' },
    ],
  },
  ring: {
    id: 'ring', short: '环状结构', title: '记录附加特征', question: '星系中是否存在完整或近完整的环状结构？',
    hint: '环应围绕中心闭合或近似闭合，不要把一段旋臂误认为环。', options: answerOptions,
    examples: [
      { title: '是：有环状结构', image: namedExample('奇特特征-环状结构-Y.png', barredExample), note: '结构围绕中心闭合或接近闭合。' },
      { title: '否：无环状结构', image: namedExample('奇特特征-环状结构-N.png', armsExample), note: '没有能够辨认为完整或近完整环的结构。' },
    ],
  },
  dust: {
    id: 'dust', short: '尘埃带', title: '记录附加特征', question: '是否能看到明显的暗色尘埃带？',
    hint: '尘埃会吸收背景星光，常表现为穿过亮盘或核球的暗纹。', options: answerOptions,
    examples: [
      { title: '是：有尘埃带', image: namedExample('奇特特征-尘埃带-Y.png', edgeExample), note: '可见吸收星光形成的明显暗色带状结构。' },
      { title: '否：无尘埃带', image: namedExample('奇特特征-尘埃带-N.png', armsExample), note: '没有能够明确辨认的暗色吸收带。' },
    ],
  },
  lens: {
    id: 'lens', short: '透镜多像', title: '记录附加特征', question: '周围是否出现疑似引力透镜多重像？',
    hint: '寻找围绕同一前景中心分布、颜色相近的重复小像。', options: answerOptions,
    examples: [
      { title: '是：有引力透镜多像', image: namedExample('奇特特征-引力透镜多像-Y.jpg', smoothExample), note: '多个相似像围绕同一个前景质量中心分布。' },
      { title: '否：无引力透镜多像', image: namedExample('奇特特征-引力透镜多像-N.png', armsExample), note: '周围没有符合多重成像特征的重复像。' },
    ],
  },
  arc: {
    id: 'arc', short: '透镜弧', title: '记录附加特征', question: '是否存在围绕前景中心弯曲的引力透镜弧？',
    hint: '透镜弧通常细长、弯曲，曲率中心大致指向前景天体。', options: answerOptions,
    examples: [
      { title: '是：有引力透镜弧状像', image: namedExample('奇特特征-引力透镜弧状-Y.jpg', armsExample), note: '可见围绕前景中心弯曲的独立细长像。' },
      { title: '否：无引力透镜弧状像', image: namedExample('奇特特征-引力透镜弧状-N.png', edgeExample), note: '没有符合引力透镜弧形态的结构。' },
    ],
  },
  special: {
    id: 'special', short: '其他结构', title: '完成观察记录', question: '是否还有无法归入以上类别的特殊结构？',
    hint: '例如喷流、壳层、极环或强烈不对称。只在图像中确实可见时选择“是”。', options: answerOptions,
    examples: [
      { title: '是：存在其他特殊结构', image: namedExample('特殊结构-Y.jpg', armsExample), note: '可见无法归入环、尘埃带或透镜等前述类别的异常结构。' },
      { title: '否：没有其他特殊结构', image: namedExample('特殊结构-N.jpg', smoothExample), note: '图像中的形态能够由前面已经判断的常规结构解释。' },
    ],
  },
}

const edgeOnBulgeExamples: Example[] = [
  { title: '是：Edge-on 中有核球', image: namedExample('是否有核球结构（edge-on）-Y.png', edgeExample), note: '狭长盘面中央存在明显增厚、增亮的隆起。' },
  { title: '否：Edge-on 中无核球', image: namedExample('是否有核球结构（edge-on）-N.png', smoothExample), note: '侧视盘中央没有能够明确辨认的核球隆起。' },
]

const categoryProfiles = [
  {
    images: [level01Image, armsExample],
    clue: '寻找从中心向外连续卷绕的弧状旋臂，并确认中心没有明显棒。',
    science: '旋臂中的蓝色亮结通常与新生恒星有关，但分类仍应依据结构而不是只看颜色。',
  },
  {
    images: [level02Image, smoothExample],
    clue: '观察亮度是否平滑衰减，以及是否真的存在盘面、旋臂或尘埃纹理。',
    science: '椭圆星系通常整体光滑且缺少明显旋臂，视觉结论还可用光谱和运动学进一步验证。',
  },
  {
    images: [barredExample],
    clue: '确认贯穿核心的是笔直亮带，并观察旋臂是否从棒的两端展开。',
    science: '棒结构可以重新分配盘内角动量，并可能把气体输运到星系中心。',
  },
  {
    images: [edgeExample],
    clue: '寻找狭长盘面、中央核球与可能横穿盘面的暗尘埃带。',
    science: '侧视角度会让盘面结构重叠，尘埃带也可能遮挡核球，因此不再继续判断旋臂和棒。',
  },
  {
    images: [smoothExample, level02Image],
    clue: '确认它具有盘和核球，但盘面上没有能连续追踪的旋臂。',
    science: '透镜星系同时具有盘与核球，却缺少明显旋臂，是椭圆星系与旋涡星系之间容易混淆的类型。',
  },
] as const

const TOTAL_LEVELS = 36

const levels: Level[] = Array.from({ length: TOTAL_LEVELS }, (_, index) => {
  const profile = categoryProfiles[index % categoryProfiles.length]
  const variant = Math.floor(index / categoryProfiles.length)
  const hour = String((index * 7 + 8) % 24).padStart(2, '0')
  const minute = String((index * 13 + 17) % 60).padStart(2, '0')
  const degree = String((index * 11 + 3) % 48).padStart(2, '0')
  return {
    id: index + 1,
    catalog: `SIM–GM J${hour}${minute}${index % 2 ? '−' : '+'}${degree}${String((index * 5 + 9) % 60).padStart(2, '0')}`,
    title: `仿真星系 ${String(index + 1).padStart(2, '0')}`,
    image: profile.images[variant % profile.images.length],
    ra: `${hour}:${minute}:${String((index * 19 + 12) % 60).padStart(2, '0')}.${index % 10}`,
    dec: `${index % 2 ? '−' : '+'}${degree}:${String((index * 9 + 7) % 60).padStart(2, '0')}:${String((index * 17 + 5) % 60).padStart(2, '0')}`,
    redshift: (0.041 + index * 0.006).toFixed(3),
    magnitude: (16.72 + (index % 9) * 0.21).toFixed(2),
    clue: profile.clue,
    science: profile.science,
  }
})

const size = 9
const directions: Record<Direction, { dr: number; dc: number; opposite: Direction }> = {
  up: { dr: -1, dc: 0, opposite: 'down' }, right: { dr: 0, dc: 1, opposite: 'left' },
  down: { dr: 1, dc: 0, opposite: 'up' }, left: { dr: 0, dc: -1, opposite: 'right' },
}

const makeMaze = (initialSeed: number) => {
  let seed = initialSeed >>> 0
  const random = () => {
    seed = (seed * 1664525 + 1013904223) >>> 0
    return seed / 4294967296
  }
  const maze: Cell[] = Array.from({ length: size * size }, (_, index) => ({
    row: Math.floor(index / size), col: index % size,
    walls: { up: true, right: true, down: true, left: true },
  }))
  const seen = new Set<number>([0])
  const stack = [0]
  while (stack.length) {
    const currentIndex = stack[stack.length - 1]
    const current = maze[currentIndex]
    const candidates = (Object.keys(directions) as Direction[])
      .map((dir) => ({ dir, row: current.row + directions[dir].dr, col: current.col + directions[dir].dc }))
      .filter(({ row, col }) => row >= 0 && row < size && col >= 0 && col < size && !seen.has(row * size + col))
    if (!candidates.length) { stack.pop(); continue }
    const choice = candidates[Math.floor(random() * candidates.length)]
    const nextIndex = choice.row * size + choice.col
    current.walls[choice.dir] = false
    maze[nextIndex].walls[directions[choice.dir].opposite] = false
    seen.add(nextIndex)
    stack.push(nextIndex)
  }
  return maze
}

const findPath = (maze: Cell[]) => {
  const goal = maze.length - 1
  const queue = [0]
  const previous = new Map<number, number>()
  const seen = new Set<number>([0])
  while (queue.length) {
    const currentIndex = queue.shift()!
    if (currentIndex === goal) break
    const current = maze[currentIndex]
    ;(Object.keys(directions) as Direction[]).forEach((dir) => {
      if (current.walls[dir]) return
      const next = (current.row + directions[dir].dr) * size + current.col + directions[dir].dc
      if (!seen.has(next)) { seen.add(next); previous.set(next, currentIndex); queue.push(next) }
    })
  }
  const path = [goal]
  while (path[0] !== 0) {
    const previousCell = previous.get(path[0])
    if (previousCell === undefined) throw new Error('Maze path generation failed')
    path.unshift(previousCell)
  }
  return path
}

const makeLevelMaze = (seed: number) => {
  let bestMaze = makeMaze(seed)
  let bestPath = findPath(bestMaze)
  for (let attempt = 1; attempt < 120 && bestPath.length < 42; attempt += 1) {
    const candidateMaze = makeMaze(seed + attempt * 977)
    const candidatePath = findPath(candidateMaze)
    if (candidatePath.length > bestPath.length) { bestMaze = candidateMaze; bestPath = candidatePath }
  }
  return { maze: bestMaze, path: bestPath }
}

const currentLevelIndex = ref(0)
const mazeSeed = ref(24681357)
const cells = ref<Cell[]>([])
const solutionPath = ref<number[]>([])
const position = ref(0)
const visited = ref(new Set<number>([0]))
const moves = ref(0)
const currentQuestionCell = ref<number | null>(null)
const answeredCells = ref(new Map<number, AnsweredCell>())
const history = ref<HistoryStep[]>([])
const currentNodeId = ref('galaxy')
const classificationReady = ref(false)
const selectedAnswer = ref<AnswerValue | ''>('')
const questionKeyboardLayer = ref<'answers' | 'actions'>('answers')
const showQuestion = ref(false)
const showGuide = ref(false)
const showPuzzle = ref(false)
const showCompletedPuzzles = ref(false)
const showPuzzleComplete = ref(false)
const showRewardAnimation = ref(false)
const guideTab = ref<'morphology' | 'rules' | 'tree'>('morphology')
const levelOutcome = ref<LevelOutcome | null>(null)
const completedPieces = ref(new Set<number>())
const completedLevelIds = ref(new Set<number>())
const completedPuzzleIds = ref(new Set<string>())
const currentPuzzle = ref<PuzzleDefinition>(randomPuzzleCandidate())
const scoreBalance = ref(0)
const totalScore = ref(0)
const bankedPieces = ref(0)
const pendingRewardPieces = ref<number[]>([])
const puzzleCompletedPending = ref(false)
const allComplete = ref(false)
const checkingAnswer = ref(false)
const checkError = ref('')
const databaseLevelNames = ref<Record<number, string>>({})
const databaseLevelImages = ref<Record<number, string>>({})
const databaseLevelIds = ref<number[]>([])
const authReady = ref(false)
const authToken = ref(localStorage.getItem('galaxy-auth-token') || '')
const authRole = ref<UserRole | null>(null)
const authDisplayName = ref('')
const loginUsername = ref('')
const loginPassword = ref('')
const loginError = ref('')
const loginBusy = ref(false)
const adminLevels = ref<AdminLevel[]>([])
const adminLoading = ref(false)
const adminError = ref('')
const adminSelectedLevel = ref<AdminLevel | null>(null)
const adminHistory = ref<HistoryStep[]>([])
const adminCurrentNodeId = ref('galaxy')
const adminReadyToSave = ref(false)
const adminSaving = ref(false)
const adminSaveMessage = ref('')

const currentLevel = computed(() => levels[currentLevelIndex.value])
const currentGalaxyName = computed(() => databaseLevelNames.value[currentLevel.value.id] || currentLevel.value.title)
const currentGalaxyImage = computed(() => databaseLevelImages.value[currentLevel.value.id] || currentLevel.value.image)
const completedPuzzles = computed(() => puzzleCandidates.filter((puzzle) => completedPuzzleIds.value.has(puzzle.id)))
const currentQuestion = computed(() => questions[currentNodeId.value])
const currentQuestionExamples = computed(() => {
  const reachedBulgeFromEdgeOn = currentNodeId.value === 'bulge'
    && history.value.some((step) => step.nodeId === 'edge' && step.value === 'yes')
  return reachedBulgeFromEdgeOn ? edgeOnBulgeExamples : currentQuestion.value.examples
})
const adminCurrentQuestion = computed(() => questions[adminCurrentNodeId.value])
const progress = computed(() => Math.round((completedPieces.value.size / PUZZLE_SIZE) * 100))
const currentStep = computed(() => history.value.length + 1)
const mazeProgress = computed(() => classificationReady.value ? 100 : Math.min(92, Math.round((history.value.length / 11) * 100)))
const pieceClasses = (index: number) => {
  const row = Math.floor(index / 6)
  const col = index % 6
  return [`piece-row-${row}`, `piece-col-${col}`]
}

type PuzzleEdge = 'flat' | 'tab' | 'notch'
const oppositePuzzleEdge = (edge: PuzzleEdge): PuzzleEdge => edge === 'tab' ? 'notch' : edge === 'notch' ? 'tab' : 'flat'
const rightPuzzleEdge = (row: number, col: number): PuzzleEdge => col === 5 ? 'flat' : (row + col) % 2 === 0 ? 'tab' : 'notch'
const bottomPuzzleEdge = (row: number, col: number): PuzzleEdge => row === 5 ? 'flat' : (row + col) % 2 === 0 ? 'notch' : 'tab'
const puzzleEdges = (index: number) => {
  const row = Math.floor(index / 6)
  const col = index % 6
  return {
    top: row === 0 ? 'flat' as const : oppositePuzzleEdge(bottomPuzzleEdge(row - 1, col)),
    right: rightPuzzleEdge(row, col),
    bottom: bottomPuzzleEdge(row, col),
    left: col === 0 ? 'flat' as const : oppositePuzzleEdge(rightPuzzleEdge(row, col - 1)),
  }
}
const puzzlePiecePath = (index: number) => {
  const edges = puzzleEdges(index)
  const top = edges.top === 'flat' ? 'L100 0' : `L38 0 A12 12 0 0 ${edges.top === 'tab' ? 1 : 0} 62 0 L100 0`
  const right = edges.right === 'flat' ? 'L100 100' : `L100 38 A12 12 0 0 ${edges.right === 'tab' ? 1 : 0} 100 62 L100 100`
  const bottom = edges.bottom === 'flat' ? 'L0 100' : `L62 100 A12 12 0 0 ${edges.bottom === 'tab' ? 1 : 0} 38 100 L0 100`
  const left = edges.left === 'flat' ? 'L0 0' : `L0 62 A12 12 0 0 ${edges.left === 'tab' ? 1 : 0} 0 38 L0 0`
  return `M0 0 ${top} ${right} ${bottom} ${left} Z`
}
const puzzleImagePosition = (index: number) => ({
  x: -(index % 6) * 100,
  y: -Math.floor(index / 6) * 100,
})

const playerProgressKey = 'galaxy-maze-player-progress-v3'
const persistPlayerProgress = () => {
  localStorage.setItem(playerProgressKey, JSON.stringify({
    completedPieces: [...completedPieces.value],
    completedLevels: [...completedLevelIds.value],
    completedPuzzles: [...completedPuzzleIds.value],
    currentPuzzleId: currentPuzzle.value.id,
    scoreBalance: scoreBalance.value,
    totalScore: totalScore.value,
    bankedPieces: bankedPieces.value,
  }))
}

const restorePlayerProgress = () => {
  try {
    const stored = JSON.parse(localStorage.getItem(playerProgressKey) || '{}')
    completedPieces.value = new Set((stored.completedPieces || []).filter((value: unknown) => Number.isInteger(value) && Number(value) >= 0 && Number(value) < PUZZLE_SIZE))
    completedLevelIds.value = new Set((stored.completedLevels || []).filter((value: unknown) => Number.isInteger(value)).map(Number))
    const validPuzzleIds = new Set(puzzleCandidates.map((puzzle) => puzzle.id))
    const migratePuzzleId = (value: unknown) => value === 'puzzle-galaxy' ? 'puzzle-puzzle-galaxy.png' : String(value || '')
    completedPuzzleIds.value = new Set((stored.completedPuzzles || []).map(migratePuzzleId).filter((id: string) => validPuzzleIds.has(id)))
    const restoredPuzzleId = migratePuzzleId(stored.currentPuzzleId)
    currentPuzzle.value = puzzleCandidates.find((puzzle) => puzzle.id === restoredPuzzleId) || randomPuzzleCandidate()
    scoreBalance.value = Math.max(0, Math.min(99, Number(stored.scoreBalance) || 0))
    totalScore.value = Math.max(0, Number(stored.totalScore) || 0)
    bankedPieces.value = Math.max(0, Number(stored.bankedPieces) || 0)
    if (completedPieces.value.size === PUZZLE_SIZE) {
      completedPuzzleIds.value = new Set([...completedPuzzleIds.value, currentPuzzle.value.id])
      puzzleCompletedPending.value = true
      showPuzzleComplete.value = true
    }

  } catch {
    localStorage.removeItem(playerProgressKey)
  }
}

const randomItem = <T,>(items: T[]) => items[Math.floor(Math.random() * items.length)]
const randomUncollectedSlots = (count: number) => {
  const available = puzzleSlots.filter((slot) => !completedPieces.value.has(slot))
  for (let index = available.length - 1; index > 0; index -= 1) {
    const swapIndex = Math.floor(Math.random() * (index + 1))
    ;[available[index], available[swapIndex]] = [available[swapIndex], available[index]]
  }
  return available.slice(0, count)
}

const finishCurrentPuzzle = () => {
  completedPuzzleIds.value = new Set([...completedPuzzleIds.value, currentPuzzle.value.id])
  puzzleCompletedPending.value = true
  persistPlayerProgress()
}

const animatePuzzleRewards = async (slots: number[]) => {
  if (!slots.length) return
  pendingRewardPieces.value = slots
  showRewardAnimation.value = true
  await nextTick()
  await new Promise((resolve) => window.setTimeout(resolve, 650))

  const animations = slots.map((slot) => {
    const source = document.querySelector<HTMLElement>(`.reward-piece[data-reward-slot="${slot}"]`)
    const target = document.querySelector<HTMLElement>(`.mini-puzzle [data-puzzle-slot="${slot}"]`)
    if (!source || !target || typeof source.animate !== 'function') return Promise.resolve()
    const sourceRect = source.getBoundingClientRect()
    const targetRect = target.getBoundingClientRect()
    const dx = targetRect.left + targetRect.width / 2 - (sourceRect.left + sourceRect.width / 2)
    const dy = targetRect.top + targetRect.height / 2 - (sourceRect.top + sourceRect.height / 2)
    const scale = Math.max(.12, targetRect.width / Math.max(1, sourceRect.width))
    const animation = source.animate([
      { transform: 'translate(0, 0) scale(1)', opacity: 1 },
      { transform: `translate(${dx}px, ${dy}px) scale(${scale})`, opacity: .25 },
    ], { duration: 900, delay: slots.indexOf(slot) * 90, easing: 'cubic-bezier(.3,.75,.2,1)', fill: 'forwards' })
    return animation.finished.catch(() => undefined)
  })
  await Promise.all(animations)

  completedPieces.value = new Set([...completedPieces.value, ...slots])
  pendingRewardPieces.value = []
  showRewardAnimation.value = false
  if (completedPieces.value.size === PUZZLE_SIZE) finishCurrentPuzzle()
  persistPlayerProgress()
}

const downloadPuzzle = (puzzle: PuzzleDefinition = currentPuzzle.value) => {
  const link = document.createElement('a')
  const extension = puzzle.image.match(/\.(png|jpe?g|webp)(?:[?#]|$)/i)?.[1]?.toLowerCase() || 'png'
  link.href = puzzle.image
  link.download = `${puzzle.name || 'galaxy-puzzle'}.${extension === 'jpeg' ? 'jpg' : extension}`
  document.body.appendChild(link)
  link.click()
  link.remove()
}

const closeCompletedPuzzles = () => {
  showCompletedPuzzles.value = false
  if (puzzleCompletedPending.value) showPuzzleComplete.value = true
}

const cellStyle = (cell: Cell) => ({
  borderTopColor: cell.walls.up ? 'rgba(94, 218, 205, .62)' : 'transparent',
  borderRightColor: cell.walls.right ? 'rgba(94, 218, 205, .62)' : 'transparent',
  borderBottomColor: cell.walls.down ? 'rgba(94, 218, 205, .62)' : 'transparent',
  borderLeftColor: cell.walls.left ? 'rgba(94, 218, 205, .62)' : 'transparent',
})

const nodeToField: Record<string, DatabaseAnswerField> = {
  galaxy: 'has_galaxy',
  dominant: 'one_dominant',
  overlap: 'components_overlap',
  elliptical: 'is_elliptical',
  edge: 'is_edge_on',
  bulge: 'has_bulge',
  bar: 'has_bar',
  arms: 'has_spiral_arms',
  ring: 'has_ring',
  dust: 'has_dust_lane',
  lens: 'has_lens_multiple',
  arc: 'has_lens_arc',
  special: 'has_special',
}

const attributeLabels: Record<DatabaseAnswerField, string> = {
  has_galaxy: '是否包含星系图像',
  one_dominant: '是否有一个主导成分',
  components_overlap: '各成分是否有重叠',
  is_elliptical: '是否为椭圆星系',
  is_edge_on: '是否为 Edge-on 星系',
  has_bulge: '是否有核球结构',
  has_bar: '是否有棒状结构',
  has_spiral_arms: '是否有旋臂结构',
  has_ring: '是否有环状结构',
  has_dust_lane: '是否有尘埃带',
  has_lens_multiple: '是否有引力透镜多像',
  has_lens_arc: '是否有引力透镜弧状像',
  has_special: '是否有其他特殊结构',
}

const createAnswersFromHistory = (sourceHistory: HistoryStep[]) => {
  const answers: Record<DatabaseAnswerField, DatabaseAnswer> = {
    has_galaxy: '未选择',
    one_dominant: '未选择',
    components_overlap: '未选择',
    is_elliptical: '未选择',
    is_edge_on: '未选择',
    has_bulge: '未选择',
    has_bar: '未选择',
    has_spiral_arms: '未选择',
    has_ring: '未选择',
    has_dust_lane: '未选择',
    has_lens_multiple: '未选择',
    has_lens_arc: '未选择',
    has_special: '未选择',
  }

  sourceHistory.forEach((step) => {
    const field = nodeToField[step.nodeId]
    if (field) answers[field] = step.value === 'yes' ? '是' : '否'
  })

  return answers
}

const createSubmittedAnswers = () => createAnswersFromHistory(history.value)

const resolveAnswer = (nodeId: string, value: AnswerValue) => {
  if (nodeId === 'galaxy') {
    if (value === 'yes') return 'dominant'
    return 'finish'
  }
  if (nodeId === 'dominant') return value === 'yes' ? 'elliptical' : 'overlap'
  if (nodeId === 'overlap') return 'ring'
  if (nodeId === 'elliptical') {
    if (value === 'yes') return 'ring'
    return 'edge'
  }
  if (nodeId === 'edge') return value === 'yes' ? 'bulge' : 'bar'
  if (nodeId === 'bar') return 'arms'
  if (nodeId === 'arms') return 'bulge'
  if (nodeId === 'bulge') return 'ring'
  if (nodeId === 'ring') return 'dust'
  if (nodeId === 'dust') return 'lens'
  if (nodeId === 'lens') return 'arc'
  if (nodeId === 'arc') return 'special'
  return 'finish'
}

const databaseAnswerFields = Object.values(nodeToField) as DatabaseAnswerField[]
const authenticatedHeaders = () => ({ Authorization: `Bearer ${authToken.value}` })

const loadAdminLevels = async () => {
  adminLoading.value = true
  adminError.value = ''
  try {
    const response = await fetch('/api/admin/levels', { headers: authenticatedHeaders() })
    const result = await response.json()
    if (!response.ok) throw new Error(result.message || '读取关卡失败')
    adminLevels.value = (result.levels || []).map((level: Record<string, unknown>) => ({
      id: Number(level.id),
      galaxyName: String(level.galaxyName || `星系 ${level.id}`),
      imagePath: level.imagePath ? String(level.imagePath) : null,
      answers: Object.fromEntries(
        databaseAnswerFields.map((field) => [field, ['是', '否', '未选择'].includes(String(level[field])) ? level[field] : '未选择']),
      ) as Record<DatabaseAnswerField, DatabaseAnswer>,
    }))
  } catch (error) {
    adminError.value = error instanceof Error ? error.message : '无法读取管理员关卡数据'
  } finally {
    adminLoading.value = false
  }
}

const applySession = (role: UserRole, displayName: string) => {
  authRole.value = role
  authDisplayName.value = displayName
  if (role === 'admin') void loadAdminLevels()
}

const submitLogin = async () => {
  if (!loginUsername.value.trim() || !loginPassword.value) return
  loginBusy.value = true
  loginError.value = ''
  try {
    const response = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username: loginUsername.value.trim(), password: loginPassword.value }),
    })
    const result = await response.json()
    if (!response.ok) throw new Error(result.message || '登录失败')
    authToken.value = result.token
    localStorage.setItem('galaxy-auth-token', result.token)
    applySession(result.role, result.displayName)
    loginPassword.value = ''
  } catch (error) {
    loginError.value = error instanceof Error ? error.message : '无法连接登录服务'
  } finally {
    loginBusy.value = false
  }
}

const restoreSession = async () => {
  if (!authToken.value) {
    authReady.value = true
    return
  }
  try {
    const response = await fetch('/api/auth/me', { headers: authenticatedHeaders() })
    const result = await response.json()
    if (!response.ok) throw new Error('登录已失效')
    applySession(result.role, result.displayName)
  } catch {
    authToken.value = ''
    localStorage.removeItem('galaxy-auth-token')
  } finally {
    authReady.value = true
  }
}

const logout = async () => {
  try {
    await fetch('/api/auth/logout', { method: 'POST', headers: authenticatedHeaders() })
  } finally {
    authToken.value = ''
    authRole.value = null
    authDisplayName.value = ''
    adminSelectedLevel.value = null
    localStorage.removeItem('galaxy-auth-token')
  }
}

const beginAdminAnnotation = (level: AdminLevel) => {
  adminSelectedLevel.value = level
  adminHistory.value = []
  adminCurrentNodeId.value = 'galaxy'
  adminReadyToSave.value = false
  adminSaveMessage.value = ''

  let nodeId = 'galaxy'
  for (let step = 0; step < databaseAnswerFields.length; step += 1) {
    const field = nodeToField[nodeId]
    const storedValue = level.answers[field]
    if (storedValue !== '是' && storedValue !== '否') break
    const value: AnswerValue = storedValue === '是' ? 'yes' : 'no'
    adminHistory.value.push({ nodeId, value, label: storedValue })
    const next = resolveAnswer(nodeId, value)
    if (next === 'finish') {
      adminReadyToSave.value = true
      return
    }
    nodeId = next
  }
  adminCurrentNodeId.value = nodeId
}

const answerAdminQuestion = (value: AnswerValue) => {
  if (adminReadyToSave.value) return
  const nodeId = adminCurrentNodeId.value
  adminHistory.value.push({ nodeId, value, label: value === 'yes' ? '是' : '否' })
  const next = resolveAnswer(nodeId, value)
  if (next === 'finish') adminReadyToSave.value = true
  else adminCurrentNodeId.value = next
  adminSaveMessage.value = ''
}

const undoAdminAnswer = () => {
  const previous = adminHistory.value.pop()
  if (!previous) return
  adminCurrentNodeId.value = previous.nodeId
  adminReadyToSave.value = false
  adminSaveMessage.value = ''
}

const resetAdminAnnotation = () => {
  adminHistory.value = []
  adminCurrentNodeId.value = 'galaxy'
  adminReadyToSave.value = false
  adminSaveMessage.value = ''
}

const saveAdminAnswers = async () => {
  if (!adminSelectedLevel.value || !adminReadyToSave.value || adminSaving.value) return
  adminSaving.value = true
  adminSaveMessage.value = ''
  const answers = createAnswersFromHistory(adminHistory.value)
  try {
    const response = await fetch(`/api/admin/levels/${adminSelectedLevel.value.id}/answers`, {
      method: 'PUT',
      headers: { ...authenticatedHeaders(), 'Content-Type': 'application/json' },
      body: JSON.stringify({ answers }),
    })
    const result = await response.json()
    if (!response.ok) throw new Error(result.message || '保存失败')
    adminSelectedLevel.value.answers = answers
    adminLevels.value = adminLevels.value.map((level) => level.id === adminSelectedLevel.value?.id ? { ...level, answers } : level)
    adminSaveMessage.value = '标定答案已写入 galaxy_levels'
  } catch (error) {
    adminSaveMessage.value = error instanceof Error ? error.message : '保存标定答案失败'
  } finally {
    adminSaving.value = false
  }
}

const finishLevel = async () => {
  if (checkingAnswer.value) return
  checkingAnswer.value = true
  checkError.value = ''

  try {
    const response = await fetch(`/api/levels/${currentLevel.value.id}/check`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ answers: createSubmittedAnswers() }),
    })
    const result = await response.json()
    if (!response.ok) throw new Error(result.message || '判题请求失败')

    const correct = result.correct === true
    const correctCount = Math.max(0, Number(result.correctCount) || 0)
    const answeredCount = Math.max(correctCount, Number(result.answeredCount) || history.value.length)
    const earnedPoints = correctCount * POINTS_PER_CORRECT + (correct ? LEVEL_CLEAR_BONUS : 0)
    const combinedScore = scoreBalance.value + earnedPoints
    const pieceRewards = Math.floor(combinedScore / 100)
    scoreBalance.value = combinedScore % 100
    totalScore.value += earnedPoints

    if (correct) completedLevelIds.value = new Set([...completedLevelIds.value, currentLevel.value.id])

    const remainingSlots = PUZZLE_SIZE - completedPieces.value.size
    const awardedSlots = randomUncollectedSlots(Math.min(pieceRewards, remainingSlots))
    bankedPieces.value += Math.max(0, pieceRewards - awardedSlots.length)
    const outcome: LevelOutcome = { correct, correctCount, answeredCount, earnedPoints, awardedPieces: pieceRewards }

    checkingAnswer.value = false
    await animatePuzzleRewards(awardedSlots)
    levelOutcome.value = outcome
    persistPlayerProgress()
  } catch (error) {
    checkError.value = error instanceof Error ? error.message : '无法连接数据库判题服务'
  } finally {
    checkingAnswer.value = false
  }
}

const retryDatabaseCheck = () => {
  checkError.value = ''
  void finishLevel()
}

const tailQuestionOffsets: Partial<Record<string, number>> = {
  ring: 18,
  dust: 14,
  lens: 10,
  arc: 6,
  special: 2,
}

const placeNextQuestion = (answer: AnswerValue, nextNodeId: string) => {
  const currentCursor = Math.max(0, solutionPath.value.indexOf(position.value))
  const lastCursor = solutionPath.value.length - 1
  const tailOffset = tailQuestionOffsets[nextNodeId]
  const preferredCursor = tailOffset === undefined
    ? currentCursor + (answer === 'yes' ? 2 : 4)
    : lastCursor - tailOffset
  const nextCursor = Math.min(lastCursor - 1, Math.max(currentCursor + 2, preferredCursor))
  currentQuestionCell.value = solutionPath.value[nextCursor]
}

const confirmAnswer = () => {
  if (!selectedAnswer.value || levelOutcome.value) return
  const option = currentQuestion.value.options.find((item) => item.value === selectedAnswer.value)
  if (!option) return
  const answeredNodeId = currentNodeId.value
  const answer = selectedAnswer.value
  const next = resolveAnswer(answeredNodeId, answer)
  if (currentQuestionCell.value !== null) {
    answeredCells.value = new Map(answeredCells.value).set(currentQuestionCell.value, { nodeId: answeredNodeId, label: option.label, value: answer })
  }
  history.value = [...history.value, { nodeId: answeredNodeId, value: answer, label: option.label }]
  selectedAnswer.value = ''
  showQuestion.value = false
  if (next === 'finish') {
    classificationReady.value = true
    currentQuestionCell.value = null
  } else {
    currentNodeId.value = next
    placeNextQuestion(answer, next)
  }
}

const setupLevel = () => {
  const generated = makeLevelMaze(mazeSeed.value + currentLevel.value.id * 7919)
  cells.value = generated.maze
  solutionPath.value = generated.path
  position.value = 0
  visited.value = new Set([0])
  moves.value = 0
  history.value = []
  answeredCells.value = new Map()
  currentNodeId.value = 'galaxy'
  currentQuestionCell.value = solutionPath.value[Math.min(4, solutionPath.value.length - 2)]
  classificationReady.value = false
  selectedAnswer.value = ''
  showQuestion.value = false
  levelOutcome.value = null
  checkError.value = ''
  allComplete.value = false
}

const move = (dir: Direction) => {
  if (showQuestion.value || showGuide.value || showPuzzle.value || showRewardAnimation.value || showPuzzleComplete.value || showCompletedPuzzles.value || levelOutcome.value || allComplete.value || checkingAnswer.value || checkError.value) return
  const current = cells.value[position.value]
  if (!current || current.walls[dir]) return
  position.value = (current.row + directions[dir].dr) * size + current.col + directions[dir].dc
  visited.value = new Set([...visited.value, position.value])
  moves.value += 1
  if (position.value === currentQuestionCell.value) showQuestion.value = true
  else if (position.value === cells.value.length - 1 && classificationReady.value) void finishLevel()
}

const restartLevel = () => setupLevel()
const resetGame = () => {
  currentLevelIndex.value = 0
  completedPieces.value = new Set()
  completedLevelIds.value = new Set()
  completedPuzzleIds.value = new Set()
  currentPuzzle.value = randomPuzzleCandidate()
  scoreBalance.value = 0
  totalScore.value = 0
  bankedPieces.value = 0
  puzzleCompletedPending.value = false
  showPuzzle.value = false
  showPuzzleComplete.value = false
  showCompletedPuzzles.value = false
  localStorage.removeItem(playerProgressKey)
  selectNextRandomLevel()
}

const selectNextRandomLevel = () => {
  const sourceIds = databaseLevelIds.value.length ? databaseLevelIds.value : levels.map((level) => level.id)
  const remaining = sourceIds.filter((id) => !completedLevelIds.value.has(id) && levels.some((level) => level.id === id))
  if (!remaining.length) {
    levelOutcome.value = null
    allComplete.value = true
    return
  }
  const withoutCurrent = remaining.filter((id) => id !== currentLevel.value.id)
  const nextId = randomItem(withoutCurrent.length ? withoutCurrent : remaining)
  currentLevelIndex.value = Math.max(0, levels.findIndex((level) => level.id === nextId))
  mazeSeed.value = Math.floor(Math.random() * 0x7fffffff)
  setupLevel()
}

const advanceLevel = () => {
  levelOutcome.value = null
  selectNextRandomLevel()
}
const continueGame = () => {
  if (puzzleCompletedPending.value) {
    levelOutcome.value = null
    showPuzzleComplete.value = true
  } else advanceLevel()
}
const skipGalaxy = () => continueGame()

const restartLevelPool = () => {
  completedLevelIds.value = new Set()
  allComplete.value = false
  persistPlayerProgress()
  selectNextRandomLevel()
}

const startNextPuzzle = () => {
  const unused = puzzleCandidates.filter((puzzle) => !completedPuzzleIds.value.has(puzzle.id) && puzzle.id !== currentPuzzle.value.id)
  const alternatives = puzzleCandidates.filter((puzzle) => puzzle.id !== currentPuzzle.value.id)
  currentPuzzle.value = randomItem(unused.length ? unused : alternatives.length ? alternatives : puzzleCandidates)
  completedPieces.value = new Set()
  puzzleCompletedPending.value = false
  showPuzzleComplete.value = false

  if (bankedPieces.value > 0) {
    const carriedSlots = randomUncollectedSlots(Math.min(PUZZLE_SIZE, bankedPieces.value))
    completedPieces.value = new Set(carriedSlots)
    bankedPieces.value -= carriedSlots.length
    if (completedPieces.value.size === PUZZLE_SIZE) finishCurrentPuzzle()
  }
  persistPlayerProgress()
  if (puzzleCompletedPending.value) showPuzzleComplete.value = true
  else selectNextRandomLevel()
}

const resolveDatabaseImage = (imagePath: string | null | undefined, levelId: number) => {
  const normalizedPath = (imagePath || '').replace(/\\/g, '/')
  const filename = normalizedPath.split('/').pop() || ''
  const numberedFilename = `level-${String(levelId).padStart(2, '0')}.png`
  return levelImagesByFilename[filename] || levelImagesByFilename[numberedFilename] || levels[levelId - 1]?.image || level01Image
}

const loadDatabaseLevels = async () => {
  try {
    const response = await fetch('/api/levels')
    if (!response.ok) return
    const result = await response.json()
    const databaseLevels = (result.levels || []) as Array<{ id: number; galaxyName: string; imagePath: string }>
    databaseLevelIds.value = databaseLevels.map((level) => level.id)
    databaseLevelNames.value = Object.fromEntries(databaseLevels.map((level) => [level.id, level.galaxyName]))
    databaseLevelImages.value = Object.fromEntries(
      databaseLevels.map((level) => [level.id, resolveDatabaseImage(level.imagePath, level.id)]),
    )
    if (!history.value.length && moves.value === 0 && !levelOutcome.value) selectNextRandomLevel()
  } catch {
    // 数据库名称暂时不可用时，继续显示内置的关卡占位名称。
  }
}

const cycleAnswer = (delta: number) => {
  const options = currentQuestion.value.options
  const nextIndex = delta < 0 ? 0 : options.length - 1
  selectedAnswer.value = options[nextIndex].value
}

type FocusDirection = 'up' | 'right' | 'down' | 'left'
const visibleModal = () => Array.from(document.querySelectorAll<HTMLElement>('.modal-backdrop'))
  .reverse()
  .find((element) => element.offsetParent !== null)

const moveButtonFocus = (container: HTMLElement | null, direction: FocusDirection) => {
  if (!container) return
  const buttons = Array.from(container.querySelectorAll<HTMLButtonElement>('button:not(:disabled)'))
    .filter((button) => button.offsetParent !== null)
  if (!buttons.length) return

  const active = document.activeElement as HTMLButtonElement | null
  if (!active || !buttons.includes(active)) {
    const preferred = container.querySelector<HTMLButtonElement>('.admin-level-card>button, .guide-tabs button.active, .large-puzzle .puzzle-piece.current, .result-actions button')
    ;(preferred || buttons[0]).focus()
    return
  }

  const currentRect = active.getBoundingClientRect()
  const currentX = currentRect.left + currentRect.width / 2
  const currentY = currentRect.top + currentRect.height / 2
  const candidates = buttons
    .filter((button) => button !== active)
    .map((button) => {
      const rect = button.getBoundingClientRect()
      const dx = rect.left + rect.width / 2 - currentX
      const dy = rect.top + rect.height / 2 - currentY
      const valid = direction === 'left' ? dx < -2 : direction === 'right' ? dx > 2 : direction === 'up' ? dy < -2 : dy > 2
      const primary = direction === 'left' || direction === 'right' ? Math.abs(dx) : Math.abs(dy)
      const secondary = direction === 'left' || direction === 'right' ? Math.abs(dy) : Math.abs(dx)
      return { button, valid, score: primary + secondary * 2.5 }
    })
    .filter((candidate) => candidate.valid)
    .sort((a, b) => a.score - b.score)

  candidates[0]?.button.focus()
}

const focusAfterRender = async (selector: string) => {
  await nextTick()
  document.querySelector<HTMLElement>(selector)?.focus()
}

const handleResultKeyboard = (event: KeyboardEvent) => {
  const container = document.querySelector<HTMLElement>('.result-card .result-actions')
  if (!container) return false
  const buttons = Array.from(container.querySelectorAll<HTMLButtonElement>('button:not(:disabled)'))
  if (!buttons.length) return false
  const activeIndex = buttons.findIndex((button) => button === document.activeElement)

  if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
    const nextIndex = event.key === 'ArrowLeft'
      ? Math.max(0, activeIndex < 0 ? 0 : activeIndex - 1)
      : Math.min(buttons.length - 1, activeIndex < 0 ? buttons.length - 1 : activeIndex + 1)
    buttons[nextIndex].focus()
    return true
  }
  if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
    moveButtonFocus(container, event.key === 'ArrowUp' ? 'up' : 'down')
    return true
  }
  if (event.key === ' ' || event.key === 'Enter') {
    buttons[activeIndex >= 0 ? activeIndex : 0].click()
    return true
  }
  return false
}

const handlePuzzleCompleteKeyboard = (event: KeyboardEvent) => {
  const card = document.querySelector<HTMLElement>('.puzzle-complete-card')
  if (!card) return false
  const buttons = Array.from(card.querySelectorAll<HTMLButtonElement>(
    '.result-actions button:not(:disabled), .complete-collection-button:not(:disabled)',
  )).filter((button) => button.offsetParent !== null)
  if (!buttons.length) return false

  const currentIndex = buttons.findIndex((button) => button === document.activeElement)
  if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
    const offset = event.key === 'ArrowLeft' ? -1 : 1
    const startIndex = currentIndex < 0 ? (offset > 0 ? -1 : 0) : currentIndex
    const nextIndex = (startIndex + offset + buttons.length) % buttons.length
    window.getSelection()?.removeAllRanges()
    buttons[nextIndex].focus()
    return true
  }
  if (event.key === ' ' || event.key === 'Enter') {
    const selectedButton = currentIndex >= 0 ? buttons[currentIndex] : buttons[0]
    selectedButton.focus()
    selectedButton.click()
    return true
  }
  return false
}

const handleModalButtonsKeyboard = (event: KeyboardEvent) => {
  const container = visibleModal() || null
  if (!container) return false
  window.getSelection()?.removeAllRanges()
  const buttons = Array.from(container.querySelectorAll<HTMLButtonElement>('button:not(:disabled)'))
    .filter((button) => button.offsetParent !== null)
  if (!buttons.length) return false

  if (event.key.startsWith('Arrow')) {
    const currentIndex = buttons.findIndex((button) => button === document.activeElement)
    const backwards = event.key === 'ArrowLeft' || event.key === 'ArrowUp'
    const nextIndex = currentIndex < 0
      ? 0
      : (currentIndex + (backwards ? -1 : 1) + buttons.length) % buttons.length
    buttons[nextIndex].focus()
    buttons[nextIndex].scrollIntoView({ block: 'nearest', inline: 'nearest' })
    return true
  }
  if (event.key === ' ' || event.key === 'Enter') {
    const focusedButton = document.activeElement instanceof HTMLButtonElement
      && container.contains(document.activeElement)
      ? document.activeElement
      : buttons[0]
    focusedButton.click()
    return true
  }
  return false
}

const onKeydown = (event: KeyboardEvent) => {
  const target = event.target as HTMLElement | null
  if (target?.matches('input, textarea, select, [contenteditable="true"]')) return

  if (authRole.value === 'admin') {
    if (event.key === 'Escape' && adminSelectedLevel.value) {
      adminSelectedLevel.value = null
      event.preventDefault()
      return
    }
    if (adminSelectedLevel.value) {
      if (event.key.startsWith('Arrow')) {
        const modal = visibleModal() || null
        if (!adminReadyToSave.value && (event.key === 'ArrowLeft' || event.key === 'ArrowRight')) {
          const selector = event.key === 'ArrowLeft' ? '.admin-answer-buttons .admin-yes' : '.admin-answer-buttons .admin-no'
          modal?.querySelector<HTMLButtonElement>(selector)?.focus()
        } else {
          moveButtonFocus(modal, event.key.slice(5).toLowerCase() as FocusDirection)
        }
        event.preventDefault()
      }
      return
    }
    if (event.key.startsWith('Arrow')) {
      moveButtonFocus(document.querySelector<HTMLElement>('.admin-shell'), event.key.slice(5).toLowerCase() as FocusDirection)
      event.preventDefault()
    }
    return
  }

  if (authRole.value !== 'user') return
  if (event.key === 'Escape') {
    showQuestion.value = false
    showGuide.value = false
    showPuzzle.value = false
    closeCompletedPuzzles()
    event.preventDefault()
    return
  }
  if (showRewardAnimation.value) return
  if (showPuzzleComplete.value) {
    if (handlePuzzleCompleteKeyboard(event)) event.preventDefault()
    return
  }
  if (levelOutcome.value) {
    if (handleResultKeyboard(event)) event.preventDefault()
    return
  }
  if (showGuide.value) {
    if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
      const tabs: Array<typeof guideTab.value> = ['morphology', 'rules', 'tree']
      const currentIndex = tabs.indexOf(guideTab.value)
      const offset = event.key === 'ArrowLeft' ? -1 : 1
      guideTab.value = tabs[(currentIndex + offset + tabs.length) % tabs.length]
      void focusAfterRender('.guide-tabs button.active')
      event.preventDefault()
    } else if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
      moveButtonFocus(visibleModal() || null, event.key === 'ArrowUp' ? 'up' : 'down')
      event.preventDefault()
    } else if (event.key === ' ' || event.key === 'Enter') {
      if (handleModalButtonsKeyboard(event)) event.preventDefault()
    }
    return
  }
  if (showPuzzle.value) {
    const selector = event.key === 'ArrowLeft' || event.key === 'ArrowUp'
      ? '.puzzle-modal .close-button'
      : '.puzzle-modal .puzzle-collection-button'
    if (event.key.startsWith('Arrow')) {
      window.getSelection()?.removeAllRanges()
      document.querySelector<HTMLButtonElement>(selector)?.focus()
      event.preventDefault()
    } else if (event.key === ' ' || event.key === 'Enter') {
      const focusedButton = document.activeElement instanceof HTMLButtonElement
        && document.querySelector('.puzzle-modal')?.contains(document.activeElement)
        ? document.activeElement
        : document.querySelector<HTMLButtonElement>('.puzzle-modal .puzzle-collection-button')
      focusedButton?.click()
      event.preventDefault()
    }
    return
  }
  if (showCompletedPuzzles.value) {
    const gallery = document.querySelector<HTMLElement>('.puzzle-gallery-card')
    const downloadButtons = gallery
      ? Array.from(gallery.querySelectorAll<HTMLButtonElement>('.puzzle-download-button'))
      : []
    const closeButton = gallery?.querySelector<HTMLButtonElement>('.close-button')
    const buttons = [...downloadButtons, ...(closeButton ? [closeButton] : [])]

    if (event.key.startsWith('Arrow') && buttons.length) {
      const currentIndex = buttons.findIndex((button) => button === document.activeElement)
      const backwards = event.key === 'ArrowLeft' || event.key === 'ArrowUp'
      const nextIndex = currentIndex < 0
        ? 0
        : (currentIndex + (backwards ? -1 : 1) + buttons.length) % buttons.length
      window.getSelection()?.removeAllRanges()
      buttons[nextIndex].focus()
      buttons[nextIndex].scrollIntoView({ block: 'nearest', inline: 'nearest' })
      event.preventDefault()
    } else if ((event.key === ' ' || event.key === 'Enter') && buttons.length) {
      const focusedButton = buttons.find((button) => button === document.activeElement) || buttons[0]
      focusedButton.click()
      event.preventDefault()
    }
    return
  }
  if (allComplete.value || checkError.value) {
    if (handleModalButtonsKeyboard(event)) event.preventDefault()
    return
  }
  if (checkingAnswer.value) return
  if (showQuestion.value) {
    const questionCard = document.querySelector<HTMLElement>('.question-card')
    if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
      if (questionKeyboardLayer.value === 'answers') {
        cycleAnswer(event.key === 'ArrowLeft' ? -1 : 1)
        questionCard?.focus()
      } else {
        moveButtonFocus(questionCard?.querySelector<HTMLElement>('.question-actions') || null, event.key === 'ArrowLeft' ? 'left' : 'right')
      }
    } else if (event.key === 'ArrowUp') {
      questionKeyboardLayer.value = 'answers'
      questionCard?.focus()
    } else if (event.key === 'ArrowDown') {
      questionKeyboardLayer.value = 'actions'
      const preferredAction = selectedAnswer.value
        ? questionCard?.querySelector<HTMLButtonElement>('.question-actions .primary-button:not(:disabled)')
        : questionCard?.querySelector<HTMLButtonElement>('.question-actions .back-button:not(:disabled)')
      preferredAction?.focus()
    } else if (event.key === ' ' || event.key === 'Enter') {
      if (target?.closest('.close-button')) return
      if (questionKeyboardLayer.value === 'answers') {
        const focusedAnswer = target?.closest<HTMLButtonElement>('.answer-option')?.dataset.answer as AnswerValue | undefined
        if (focusedAnswer) selectedAnswer.value = focusedAnswer
        if (selectedAnswer.value) confirmAnswer()
      } else {
        const focusedAction = target?.closest<HTMLButtonElement>('.question-actions button')
        if (focusedAction) focusedAction.click()
        else questionCard?.querySelector<HTMLButtonElement>('.question-actions button:not(:disabled)')?.focus()
      }
    }
    else return
    event.preventDefault()
    return
  }
  const keyMap: Record<string, Direction> = {
    ArrowUp: 'up', w: 'up', W: 'up', ArrowRight: 'right', d: 'right', D: 'right',
    ArrowDown: 'down', s: 'down', S: 'down', ArrowLeft: 'left', a: 'left', A: 'left',
  }
  if (keyMap[event.key]) { event.preventDefault(); move(keyMap[event.key]) }
  else if (event.key === 'p' || event.key === 'P') { event.preventDefault(); showPuzzle.value = true }
  else if (event.key === 'h' || event.key === 'H') { event.preventDefault(); showGuide.value = true }
  else if (event.key === 'r' || event.key === 'R') { event.preventDefault(); restartLevel() }
}

watch(showQuestion, async (visible) => {
  if (visible) {
    questionKeyboardLayer.value = 'answers'
    await nextTick()
    document.querySelector<HTMLElement>('.question-card')?.focus()
  }
})
watch(showGuide, (visible) => { if (visible) void focusAfterRender('.guide-tabs button.active') })
watch(showPuzzle, (visible) => {
  if (visible) {
    window.getSelection()?.removeAllRanges()
    void focusAfterRender('.puzzle-modal .puzzle-collection-button')
  }
})
watch(showCompletedPuzzles, (visible) => {
  if (visible) void focusAfterRender('.puzzle-gallery-card .puzzle-download-button, .puzzle-gallery-card .close-button')
})
watch(showPuzzleComplete, (visible) => {
  if (visible) {
    window.getSelection()?.removeAllRanges()
    void focusAfterRender('.puzzle-complete-card .result-actions button')
  }
})
watch(levelOutcome, (outcome) => { if (outcome) void focusAfterRender('.result-card .result-actions button') })
watch(checkError, (message) => { if (message) void focusAfterRender('.result-card .result-actions button') })
watch(allComplete, (visible) => { if (visible) void focusAfterRender('.complete-card .result-actions button') })
watch(adminSelectedLevel, (level) => { if (level) void focusAfterRender('.admin-annotation-card') })
watch(adminReadyToSave, (ready) => { if (ready) void focusAfterRender('.admin-save') })
restorePlayerProgress()
setupLevel()
onMounted(() => {
  window.addEventListener('keydown', onKeydown, { capture: true })
  void loadDatabaseLevels()
  void restoreSession()
})
onBeforeUnmount(() => window.removeEventListener('keydown', onKeydown, true))
</script>

<template>
  <div class="app-shell">
    <section v-if="!authReady" class="auth-screen auth-loading" aria-live="polite">
      <div class="auth-card"><span class="brand-orbit" aria-hidden="true"><i></i></span><p>正在确认登录状态…</p></div>
    </section>

    <section v-else-if="!authRole" class="auth-screen">
      <form class="auth-card login-card" @submit.prevent="submitLogin">
        <div class="auth-brand"><span class="brand-orbit" aria-hidden="true"><i></i></span><div><b>星系迷航</b><small>GALAXY MAZE · MORPHOLOGY LAB</small></div></div>
        <p class="eyebrow">IDENTITY VERIFICATION</p>
        <h1>登录星系形态实验室</h1>
        <p>用户进入星系识别迷宫；管理员进入关卡答案标定台。</p>
        <label><span>账号</span><input v-model="loginUsername" autocomplete="username" placeholder="请输入账号"></label>
        <label><span>密码</span><input v-model="loginPassword" type="password" autocomplete="current-password" placeholder="请输入密码"></label>
        <p v-if="loginError" class="auth-error">{{ loginError }}</p>
        <button class="primary-button auth-submit" type="submit" :disabled="loginBusy || !loginUsername.trim() || !loginPassword">{{ loginBusy ? '正在登录…' : '进入系统' }}</button>
        <div class="demo-accounts"><span>用户：user / galaxy123</span><span>管理员：admin / admin123</span></div>
      </form>
    </section>

    <section v-else-if="authRole === 'admin'" class="admin-shell">
      <header class="admin-header"><div class="auth-brand"><span class="brand-orbit" aria-hidden="true"><i></i></span><div><b>星系答案标定台</b><small>GALAXY LEVEL CALIBRATION</small></div></div><div><span>{{ authDisplayName }}</span><button class="ghost-button" type="button" @click="logout">退出登录</button></div></header>
      <main class="admin-main">
        <div class="admin-title"><div><p class="eyebrow">GALAXY_LEVELS</p><h1>选择星系进行快速标定</h1><p>每张图尺寸一致；点击图片后，按照决策树依次选择“是”或“否”。未进入的分支会自动保存为“未选择”。</p></div><button class="ghost-button" type="button" :disabled="adminLoading" @click="loadAdminLevels">刷新列表</button></div>
        <p v-if="adminLoading" class="admin-state">正在从数据库读取星系…</p>
        <p v-else-if="adminError" class="admin-state error">{{ adminError }}</p>
        <div v-else class="admin-level-grid">
          <article v-for="level in adminLevels" :key="level.id" class="admin-level-card">
            <button type="button" @click="beginAdminAnnotation(level)"><img :src="resolveDatabaseImage(level.imagePath, level.id)" :alt="level.galaxyName"><span>开始标定</span></button>
            <div><b>{{ level.id }}. {{ level.galaxyName }}</b><small>{{ Object.values(level.answers).filter(value => value !== '未选择').length }} 项已选择</small></div>
          </article>
        </div>
      </main>

      <div v-if="adminSelectedLevel" class="modal-backdrop admin-annotation-backdrop" role="dialog" aria-modal="true" aria-labelledby="admin-question-title" @click.self="adminSelectedLevel = null">
        <section class="admin-annotation-card" tabindex="-1">
          <button class="close-button" type="button" aria-label="关闭标定面板" @click="adminSelectedLevel = null">×</button>
          <div class="admin-galaxy-visual"><img :src="resolveDatabaseImage(adminSelectedLevel.imagePath, adminSelectedLevel.id)" :alt="adminSelectedLevel.galaxyName"><div><span>LEVEL {{ adminSelectedLevel.id }}</span><b>{{ adminSelectedLevel.galaxyName }}</b></div></div>
          <div class="admin-decision-panel">
            <p class="eyebrow">QUICK DECISION TREE · {{ adminHistory.length + (adminReadyToSave ? 0 : 1) }}</p>
            <template v-if="!adminReadyToSave">
              <h2 id="admin-question-title">{{ adminCurrentQuestion.question }}</h2>
              <p>{{ adminCurrentQuestion.hint }}</p>
              <div class="admin-answer-buttons"><button type="button" class="admin-yes" @click="answerAdminQuestion('yes')">是</button><button type="button" class="admin-no" @click="answerAdminQuestion('no')">否</button></div>
              <p class="answer-keyboard-hint admin-keyboard-hint"><span>← → 选择</span><span>空格 确认</span><span>↑ ↓ 切换操作层</span></p>
            </template>
            <template v-else>
              <h2 id="admin-question-title">决策路径已完成</h2>
              <p>确认下方记录后保存。未出现在路径中的属性将写入“未选择”。</p>
              <button class="primary-button admin-save" type="button" :disabled="adminSaving" @click="saveAdminAnswers">{{ adminSaving ? '正在写入…' : '保存到 galaxy_levels' }}</button>
            </template>
            <div class="admin-answer-history"><span v-if="!adminHistory.length">尚未选择</span><span v-for="step in adminHistory" :key="step.nodeId"><b>{{ questions[step.nodeId].short }}</b>{{ step.label }}</span></div>
            <p v-if="adminSaveMessage" class="admin-save-message">{{ adminSaveMessage }}</p>
            <div class="admin-annotation-actions"><button class="back-button" type="button" :disabled="!adminHistory.length" @click="undoAdminAnswer">撤销上一步</button><button class="ghost-button" type="button" @click="resetAdminAnnotation">从头标定</button></div>
          </div>
        </section>
      </div>
    </section>

    <template v-else>
    <main class="game-layout">
      <aside class="left-panel panel">
        <button class="brand panel-brand" type="button" @click="resetGame" aria-label="重新开始星系迷航">
          <span class="brand-orbit" aria-hidden="true"><i></i></span><span><b>星系迷航</b><small>GALAXY MAZE · MORPHOLOGY LAB</small></span>
        </button>
        <section class="puzzle-section" aria-labelledby="puzzle-title">
          <div class="section-heading"><div><p class="eyebrow">COLLECTION</p><h2 id="puzzle-title">{{ currentPuzzle.name }}</h2></div><b>{{ completedPieces.size }}/{{ PUZZLE_SIZE }}</b></div>
          <button class="puzzle-preview-button" type="button" @click="showPuzzle = true" aria-label="放大查看世界拼图">
            <span class="puzzle-board mini-puzzle">
              <span v-for="slot in puzzleSlots" :key="slot" class="puzzle-piece" :data-puzzle-slot="slot" :class="[...pieceClasses(slot), { collected: completedPieces.has(slot) }]">
                <svg class="puzzle-piece-shape" viewBox="-18 -18 136 136" aria-hidden="true"><defs><clipPath :id="`mini-puzzle-piece-${slot}`"><path :d="puzzlePiecePath(slot)" /></clipPath></defs><image :href="currentPuzzle.image" :x="puzzleImagePosition(slot).x" :y="puzzleImagePosition(slot).y" width="600" height="600" preserveAspectRatio="none" :clip-path="`url(#mini-puzzle-piece-${slot})`" /><path class="puzzle-piece-outline" :d="puzzlePiecePath(slot)" /></svg>
              </span>
            </span>
            <span class="puzzle-zoom">点击放大（P）· 随机碎片</span>
          </button>
          <div class="score-panel"><div><span>碎片积分</span><b>{{ scoreBalance }} / 100</b></div><div class="score-progress"><i :style="{ width: scoreBalance + '%' }"></i></div><small>累计 {{ totalScore }} 分 · 每满 100 分随机获得一块拼图</small></div>
        </section>

        <section class="intro-section">
          <p class="eyebrow">MISSION BRIEF</p><h1>沿着问题，<br><em>认出一座星系。</em></h1>
          <p>每关只观察一个星系。迷宫中的发光点代表问题；你的回答会打开不同的下一段路线，因此节点的数量和位置会实时改变。</p>
          <button class="guide-entry" type="button" @click="showGuide = true"><span class="info-icon" aria-hidden="true">i</span><span><b>第一次玩？点击查看操作指南（H）</b><small>形态范例 · 决策树 · 游戏规则</small></span></button>
        </section>

      </aside>

      <section class="maze-stage" aria-label="动态星系分类迷宫">
        <div class="maze-frame physical-maze">
          <div class="coordinate top">A　 B　 C　 D　 E　 F　 G　 H　 I</div>
          <div class="maze-grid" :style="{ gridTemplateColumns: `repeat(${size}, 1fr)` }">
            <div v-for="(cell, index) in cells" :key="index" class="maze-cell"
              :class="{ visited: visited.has(index), current: position === index, event: currentQuestionCell === index, done: answeredCells.has(index), goal: index === cells.length - 1, unlocked: classificationReady && index === cells.length - 1 }"
              :style="cellStyle(cell)">
              <span v-if="currentQuestionCell === index" class="question-node"><i aria-hidden="true"></i><b>{{ history.length + 1 }}</b></span>
              <span v-if="answeredCells.has(index)" class="answered-node"><i aria-hidden="true"></i><b>✓</b></span>
              <span v-if="index === cells.length - 1" class="goal-mark">{{ classificationReady ? 'EXIT' : 'LOCK' }}</span>
              <span v-if="position === index" class="probe"><img :src="currentGalaxyImage" alt=""><i aria-hidden="true"></i></span>
            </div>
          </div>
          <div class="maze-history-overlay path-summary"><span v-if="!history.length">尚未作答</span><span v-for="(step, index) in history" :key="`${step.nodeId}-${index}`">{{ questions[step.nodeId].short }}：{{ step.label }}</span></div>
          <div class="maze-meta">MAZE {{ size }}×{{ size }} / {{ moves }} MOVES / {{ history.length }} QUESTIONS</div>
        </div>
        <div class="maze-progress"><i :style="{ width: mazeProgress + '%' }"></i></div>
      </section>

      <aside class="right-rail panel">
        <div class="user-session"><span>{{ authDisplayName }}</span><button type="button" @click="logout">退出</button></div>
        <section class="target-overview">
          <p class="eyebrow">CURRENT TARGET</p><h2>{{ currentGalaxyName }}</h2>
          <div class="target-preview"><img :src="currentGalaxyImage" :alt="`${currentGalaxyName}星系图像`"><span>DATABASE IMAGE</span></div><h3>{{ currentLevel.catalog }}</h3>
          <dl class="target-data"><div><dt>赤经 RA</dt><dd>{{ currentLevel.ra }}</dd></div><div><dt>赤纬 DEC</dt><dd>{{ currentLevel.dec }}</dd></div><div><dt>红移 z</dt><dd>{{ currentLevel.redshift }}</dd></div><div><dt>r 星等</dt><dd>{{ currentLevel.magnitude }}</dd></div></dl>
        </section>
        <section class="rail-navigation">
          <p class="eyebrow">NAVIGATION</p><h3>航行控制</h3><p>方向键或 W A S D 移动 · P 拼图 · H 指南 · R 重玩本关</p>
          <div class="dpad"><button type="button" aria-label="向上" @click="move('up')">↑</button><button type="button" aria-label="向左" @click="move('left')">←</button><button type="button" aria-label="向下" @click="move('down')">↓</button><button type="button" aria-label="向右" @click="move('right')">→</button></div>
        </section>
        <div class="rail-actions"><button class="ghost-button" type="button" @click="restartLevel">重玩本关（R）</button><button class="danger-button" type="button" @click="resetGame">重新测试全部关卡</button></div>
      </aside>
    </main>

    <div v-if="showQuestion" class="modal-backdrop" role="dialog" aria-modal="true" aria-labelledby="question-title" @click.self="showQuestion = false">
      <section class="question-card" tabindex="-1">
        <button class="close-button" type="button" aria-label="关闭问题" @click="showQuestion = false">×</button>
        <div class="question-visual"><img :src="currentGalaxyImage" :alt="`${currentGalaxyName}观测图像`"><div class="scan-frame"><span>{{ currentLevel.catalog }}</span><b>当前观测目标</b></div></div>
        <div class="question-content">
          <div class="question-top"><p class="eyebrow">DECISION NODE {{ currentStep }}</p><span>第 {{ currentLevel.id }} 关</span></div><h2 id="question-title">{{ currentQuestion.title }}</h2><p class="question-text">{{ currentQuestion.question }}</p><p class="hint-text"><b>怎么观察</b>{{ currentQuestion.hint }}</p>
          <div class="example-strip"><article v-for="example in currentQuestionExamples" :key="example.title"><img :src="example.image" :alt="example.title"><div><b>{{ example.title }}</b><span>{{ example.note }}</span></div></article></div>
          <div class="answers" role="radiogroup" :aria-label="currentQuestion.question"><button v-for="option in currentQuestion.options" :key="option.value" class="answer-option" type="button" :data-answer="option.value" :class="{ selected: selectedAnswer === option.value }" role="radio" :aria-checked="selectedAnswer === option.value" @click="selectedAnswer = option.value"><span class="answer-radio"></span><span><b>{{ option.label }}</b><small>{{ option.detail }}</small></span></button></div>
          <p class="answer-keyboard-hint"><span>← → 选择答案</span><span>空格 确认</span><span>↑ ↓ 切换操作层</span></p>
          <div class="question-actions"><button class="back-button" type="button" @click="showQuestion = false">返回迷宫</button><button class="primary-button" type="button" :disabled="!selectedAnswer" @click="confirmAnswer">确认判断，更新迷宫</button></div>
        </div>
      </section>
    </div>

    <div v-if="checkingAnswer" class="modal-backdrop" role="status" aria-live="polite"><section class="result-card checking-card"><p class="eyebrow">DATABASE CHECK</p><h2>正在核对13项属性…</h2><p>标准答案保存在 MySQL 中，请稍候。</p></section></div>

    <div v-if="checkError" class="modal-backdrop" role="dialog" aria-modal="true" aria-labelledby="check-error-title"><section class="result-card"><p class="eyebrow">DATABASE UNAVAILABLE</p><h2 id="check-error-title">暂时无法完成判题</h2><p>{{ checkError }}</p><p>本次不会被记为答错，也不会丢失当前作答记录。</p><div class="result-actions"><button class="back-button" type="button" @click="restartLevel">重玩本关</button><button class="primary-button" type="button" @click="retryDatabaseCheck">重新连接并判题</button></div></section></div>

    <div v-if="showRewardAnimation" class="modal-backdrop reward-backdrop" role="status" aria-live="polite">
      <section class="reward-card">
        <p class="eyebrow">PUZZLE REWARD</p>
        <h2>获得 {{ pendingRewardPieces.length }} 块随机碎片</h2>
        <p>积分已经结算，碎片正在飞向拼图中的随机位置。</p>
        <div class="reward-pieces">
          <span v-for="slot in pendingRewardPieces" :key="slot" class="puzzle-piece collected reward-piece" :data-reward-slot="slot" :class="pieceClasses(slot)">
            <svg class="puzzle-piece-shape" viewBox="-18 -18 136 136" aria-hidden="true"><defs><clipPath :id="`reward-puzzle-piece-${slot}`"><path :d="puzzlePiecePath(slot)" /></clipPath></defs><image :href="currentPuzzle.image" :x="puzzleImagePosition(slot).x" :y="puzzleImagePosition(slot).y" width="600" height="600" preserveAspectRatio="none" :clip-path="`url(#reward-puzzle-piece-${slot})`" /><path class="puzzle-piece-outline" :d="puzzlePiecePath(slot)" /></svg>
          </span>
        </div>
      </section>
    </div>

    <div v-if="levelOutcome" class="modal-backdrop" role="dialog" aria-modal="true" aria-labelledby="result-title">
      <section class="result-card" :class="{ success: levelOutcome.correct }">
        <div class="result-art"><img :src="currentGalaxyImage" alt=""><span>本关 +{{ levelOutcome.earnedPoints }} 分</span></div>
        <p class="eyebrow">{{ levelOutcome.correct ? 'LEVEL COMPLETE' : 'SCORING COMPLETE' }}</p>
        <h2 id="result-title">{{ levelOutcome.correct ? '标定完全正确' : '本次标定已完成' }}</h2>
        <p>答对 {{ levelOutcome.correctCount }} / {{ levelOutcome.answeredCount }} 个实际问题。</p>
        <div class="score-summary"><b>+{{ levelOutcome.earnedPoints }}</b><span>本关积分</span><b>{{ levelOutcome.awardedPieces }}</b><span>获得碎片</span></div>
        <div class="result-path"><span v-for="step in history" :key="step.nodeId">{{ questions[step.nodeId].short }} {{ step.label }}</span></div>
        <div class="result-actions" :class="{ single: levelOutcome.correct }">
          <button v-if="!levelOutcome.correct" class="back-button" type="button" @click="restartLevel">再来一次</button>
          <button :class="levelOutcome.correct ? 'primary-button' : 'skip-button'" type="button" @click="levelOutcome.correct ? continueGame() : skipGalaxy()">{{ puzzleCompletedPending ? '查看完整拼图' : '下一个随机星系' }}</button>
        </div>
      </section>
    </div>

    <div v-if="allComplete" class="modal-backdrop" role="dialog" aria-modal="true" aria-labelledby="complete-title"><section class="complete-card"><div class="complete-puzzle"><img :src="currentPuzzle.image" :alt="currentPuzzle.name"></div><p class="eyebrow">GALAXY POOL COMPLETE</p><h2 id="complete-title">题库中的星系已全部正确完成</h2><p>已正确完成的星系不会重复出现。你可以重新开启题库继续积累积分，当前拼图进度会保留。</p><div class="result-actions"><button class="back-button" type="button" @click="showPuzzle = true">查看当前拼图</button><button class="primary-button" type="button" @click="restartLevelPool">重新开启题库</button></div></section></div>

    <div v-if="showPuzzle" class="modal-backdrop puzzle-backdrop" role="dialog" aria-modal="true" aria-labelledby="puzzle-modal-title" @click.self="showPuzzle = false">
      <section class="puzzle-modal"><button class="close-button" type="button" aria-label="关闭拼图" @click="showPuzzle = false">×</button><p class="eyebrow">WORLD PUZZLE · {{ completedPieces.size }} / {{ PUZZLE_SIZE }}</p><h2 id="puzzle-modal-title">{{ currentPuzzle.name }}</h2><p>积分每满 100 分会随机点亮一个位置</p><div class="large-puzzle" role="img" :aria-label="`${currentPuzzle.name}，已获得 ${completedPieces.size} 块`"><span v-for="slot in puzzleSlots" :key="slot" class="puzzle-piece" :class="[...pieceClasses(slot), { collected: completedPieces.has(slot) }]" aria-hidden="true"><svg class="puzzle-piece-shape" viewBox="-18 -18 136 136"><defs><clipPath :id="`large-puzzle-piece-${slot}`"><path :d="puzzlePiecePath(slot)" /></clipPath></defs><image :href="currentPuzzle.image" :x="puzzleImagePosition(slot).x" :y="puzzleImagePosition(slot).y" width="600" height="600" preserveAspectRatio="none" :clip-path="`url(#large-puzzle-piece-${slot})`" /><path class="puzzle-piece-outline" :d="puzzlePiecePath(slot)" /></svg></span></div><div class="puzzle-legend"><span><i class="collected-key"></i> 已获得</span><span><i></i> 尚未获得</span><span>奖励位置随机产生</span></div><button class="collection-button puzzle-collection-button" type="button" @click="showPuzzle = false; showCompletedPuzzles = true">查看完整拼图收藏 · {{ completedPuzzles.length }}</button></section>
    </div>

    <div v-if="showPuzzleComplete" class="modal-backdrop" role="dialog" aria-modal="true" aria-labelledby="puzzle-complete-title"><section class="complete-card puzzle-complete-card"><div class="complete-puzzle"><img :src="currentPuzzle.image" :alt="currentPuzzle.name"></div><p class="eyebrow">PUZZLE COMPLETE</p><h2 id="puzzle-complete-title">{{ currentPuzzle.name }} 已完成</h2><p>这幅完整拼图已经收入收藏。你可以下载图片，或随机开启下一幅拼图。</p><div class="result-actions"><button class="back-button" type="button" @click="downloadPuzzle()">下载完整拼图</button><button class="primary-button" type="button" @click="startNextPuzzle">开始下一幅拼图</button></div><button class="collection-button complete-collection-button" type="button" @click="showPuzzleComplete = false; showCompletedPuzzles = true">查看完整拼图收藏</button></section></div>

    <div v-if="showCompletedPuzzles" class="modal-backdrop puzzle-backdrop" role="dialog" aria-modal="true" aria-labelledby="collection-title" @click.self="closeCompletedPuzzles"><section class="puzzle-modal puzzle-gallery-card"><button class="close-button" type="button" aria-label="关闭收藏" @click="closeCompletedPuzzles">×</button><p class="eyebrow">COMPLETED COLLECTION</p><h2 id="collection-title">完整拼图收藏</h2><p v-if="!completedPuzzles.length" class="empty-collection">完成第一幅拼图后，它会出现在这里。</p><div v-else class="completed-puzzle-grid"><article v-for="puzzle in completedPuzzles" :key="puzzle.id"><img :src="puzzle.image" :alt="puzzle.name"><div><h3>{{ puzzle.name }}</h3><button class="ghost-button puzzle-download-button" type="button" @click="downloadPuzzle(puzzle)">下载图片</button></div></article></div></section></div>

    <div v-if="showGuide" class="modal-backdrop guide-backdrop" role="dialog" aria-modal="true" aria-labelledby="guide-title" @click.self="showGuide = false">
      <section class="guide-card"><button class="close-button" type="button" aria-label="关闭指南" @click="showGuide = false">×</button><p class="eyebrow">BEGINNER FIELD GUIDE</p><h2 id="guide-title">星系形态分类入门</h2>
        <div class="guide-tabs" role="tablist" aria-label="指南内容"><button :class="{ active: guideTab === 'morphology' }" type="button" role="tab" :aria-selected="guideTab === 'morphology'" @click="guideTab = 'morphology'">形态范例</button><button :class="{ active: guideTab === 'rules' }" type="button" role="tab" :aria-selected="guideTab === 'rules'" @click="guideTab = 'rules'">游戏规则</button><button :class="{ active: guideTab === 'tree' }" type="button" role="tab" :aria-selected="guideTab === 'tree'" @click="guideTab = 'tree'">决策树</button></div>
        <div v-if="guideTab === 'morphology'" class="morphology-guide"><article><img :src="smoothExample" alt="光滑椭圆星系仿真范例"><div><span>01</span><h3>光滑 / 椭圆</h3><p>亮度由中心向外平滑下降，没有盘面纹理与旋臂。</p></div></article><article><img :src="armsExample" alt="旋臂仿真范例"><div><span>02</span><h3>旋臂</h3><p>从中心向外卷绕的弧状结构，常带蓝色恒星形成结。</p></div></article><article><img :src="barredExample" alt="棒旋星系仿真范例"><div><span>03</span><h3>中心棒</h3><p>笔直亮带穿过中心，旋臂通常从棒的两端开始。</p></div></article><article><img :src="edgeExample" alt="侧视盘星系仿真范例"><div><span>04</span><h3>侧视盘</h3><p>盘面像狭长光带，可能有暗尘埃带横穿明亮核球。</p></div></article></div>
        <div v-else-if="guideTab === 'rules'" class="rules-guide"><article><b>1</b><div><h3>随机抽取星系</h3><p>系统从数据库随机选择星系；正确完成后暂不再出现，未完全答对的星系之后仍可能再次抽到。</p></div></article><article><b>2</b><div><h3>抵达节点自动提问</h3><p>每个发光星系代表一个问题；回答后，新节点才会出现在后续路径上。</p></div></article><article><b>3</b><div><h3>按答对题数计分</h3><p>每答对一个实际问题获得 {{ POINTS_PER_CORRECT }} 分，整关完全正确另加 {{ LEVEL_CLEAR_BONUS }} 分；结算页不会泄露标准答案。</p></div></article><article><b>4</b><div><h3>积分兑换随机碎片</h3><p>积分每满 100 分获得一个随机位置的拼图碎片，集齐后可下载并随机开启下一幅拼图。</p></div></article></div>
        <div v-else class="tree-guide"><img :src="decisionTreeImage" alt="完整星系形态分类决策树"><p>游戏中的问题名称、顺序和分支均以此图为准；迷宫只显示已经走过的节点与当前问题，尚未进入的分支不会提前出现。</p></div>
      </section>
    </div>
    </template>
  </div>
</template>
