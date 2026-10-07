/*
 Navicat Premium Dump SQL

 Source Server         : 123
 Source Server Type    : MySQL
 Source Server Version : 50719 (5.7.19)
 Source Host           : localhost:3306
 Source Schema         : galaxy_maze

 Target Server Type    : MySQL
 Target Server Version : 50719 (5.7.19)
 File Encoding         : 65001

 Date: 07/10/2026 20:00:18
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for galaxy_levels
-- ----------------------------
DROP TABLE IF EXISTS `galaxy_levels`;
CREATE TABLE `galaxy_levels`  (
  `id` tinyint(3) UNSIGNED NOT NULL,
  `galaxy_name` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `image_path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `has_galaxy` enum('是','否','未选择') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '未选择',
  `one_dominant` enum('是','否','未选择') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '未选择',
  `components_overlap` enum('是','否','未选择') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '未选择',
  `is_elliptical` enum('是','否','未选择') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '未选择',
  `is_edge_on` enum('是','否','未选择') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '未选择',
  `has_bulge` enum('是','否','未选择') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '未选择',
  `has_bar` enum('是','否','未选择') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '未选择',
  `has_spiral_arms` enum('是','否','未选择') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '未选择',
  `has_ring` enum('是','否','未选择') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '未选择',
  `has_dust_lane` enum('是','否','未选择') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '未选择',
  `has_lens_multiple` enum('是','否','未选择') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '未选择',
  `has_lens_arc` enum('是','否','未选择') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '未选择',
  `has_special` enum('是','否','未选择') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '未选择',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of galaxy_levels
-- ----------------------------
INSERT INTO `galaxy_levels` VALUES (1, '星系01', '587_39627619234220281.png', '是', '是', '未选择', '否', '是', '是', '未选择', '未选择', '否', '否', '否', '否', '否', '2026-09-16 19:59:04');
INSERT INTO `galaxy_levels` VALUES (2, '星系02', '612_39627565278696185.png', '是', '是', '未选择', '否', '否', '是', '否', '是', '否', '否', '否', '否', '否', '2026-09-16 17:46:23');
INSERT INTO `galaxy_levels` VALUES (3, '星系 03', '631_39627559360530764.png', '是', '是', '未选择', '否', '否', '否', '否', '否', '否', '否', '否', '否', '否', '2026-09-16 20:00:30');
INSERT INTO `galaxy_levels` VALUES (4, '星系 04', '784_39627559469581224.png', '是', '否', '否', '未选择', '未选择', '未选择', '未选择', '未选择', '否', '否', '否', '否', '否', '2026-09-16 20:00:53');
INSERT INTO `galaxy_levels` VALUES (5, '星系 05', '998_39627589228167610.png', '是', '是', '未选择', '否', '是', '否', '未选择', '未选择', '否', '否', '否', '否', '否', '2026-09-16 20:01:46');
INSERT INTO `galaxy_levels` VALUES (6, '星系 06', 'DESI-012.4931+02.4544.jpeg', '是', '是', '未选择', '是', '未选择', '未选择', '未选择', '未选择', '否', '否', '否', '是', '否', '2026-09-16 20:02:03');
INSERT INTO `galaxy_levels` VALUES (7, '星系 07', 'HE0435-1223.jpg', '是', '否', '否', '未选择', '未选择', '未选择', '未选择', '未选择', '否', '否', '是', '否', '否', '2026-09-16 20:02:26');
INSERT INTO `galaxy_levels` VALUES (8, '星系 08', 'HSCJ022222-022211.jpg', '是', '是', '未选择', '是', '未选择', '未选择', '未选择', '未选择', '否', '否', '否', '是', '否', '2026-09-16 20:03:14');
INSERT INTO `galaxy_levels` VALUES (9, '星系 09', 'HSCJ124453+041315.jpg', '是', '否', '否', '未选择', '未选择', '未选择', '未选择', '未选择', '否', '否', '否', '是', '否', '2026-09-16 20:06:13');
INSERT INTO `galaxy_levels` VALUES (10, '星系 10', 'SDSS1004+4112.jpg', '是', '否', '否', '未选择', '未选择', '未选择', '未选择', '未选择', '否', '否', '是', '否', '否', '2026-09-16 20:07:05');
INSERT INTO `galaxy_levels` VALUES (11, '星系 11', '129_39627595213444024.png', '是', '否', '是', '未选择', '未选择', '未选择', '未选择', '未选择', '否', '否', '否', '否', '否', '2026-09-16 20:07:28');
INSERT INTO `galaxy_levels` VALUES (12, '星系 12', '622_39627583343561200.png', '是', '是', '未选择', '否', '否', '是', '是', '否', '是', '否', '否', '否', '否', '2026-09-16 20:11:16');
INSERT INTO `galaxy_levels` VALUES (13, '星系 13', '408_39627589249140887.png', '是', '是', '未选择', '否', '否', '是', '否', '否', '否', '否', '否', '否', '否', '2026-09-16 20:12:12');
INSERT INTO `galaxy_levels` VALUES (14, '星系 14', '674_39627571247191101.png', '是', '是', '未选择', '否', '是', '否', '未选择', '未选择', '否', '是', '否', '否', '否', '2026-09-16 20:12:41');
INSERT INTO `galaxy_levels` VALUES (15, '星系 15', '5_39627583217733194.png', '是', '是', '未选择', '否', '否', '是', '是', '是', '否', '否', '否', '否', '否', '2026-09-16 20:14:44');
INSERT INTO `galaxy_levels` VALUES (16, '星系 16', '0_39627577240849068.png', '是', '是', '未选择', '否', '否', '是', '否', '是', '否', '否', '否', '否', '否', '2026-09-16 20:15:07');
INSERT INTO `galaxy_levels` VALUES (17, '星系 17', '0013m355_9039_0.96.png', '是', '否', '否', '未选择', '未选择', '未选择', '未选择', '未选择', '否', '否', '否', '否', '否', '2026-09-16 20:15:23');
INSERT INTO `galaxy_levels` VALUES (18, '星系 18', '0015m565_4408_0.96.png', '是', '否', '否', '未选择', '未选择', '未选择', '未选择', '未选择', '否', '否', '否', '否', '否', '2026-09-16 20:18:52');
INSERT INTO `galaxy_levels` VALUES (19, '星系 19', '29_39627595192468275.png', '是', '是', '未选择', '否', '否', '是', '否', '是', '否', '否', '否', '否', '否', '2026-09-16 20:19:00');
INSERT INTO `galaxy_levels` VALUES (20, '星系 20', '41_39627577266013160.png', '是', '是', '未选择', '否', '否', '是', '否', '是', '否', '是', '否', '否', '否', '2026-09-16 20:19:20');
INSERT INTO `galaxy_levels` VALUES (21, '星系 21', '49_39627583318397896.png', '是', '是', '未选择', '否', '否', '否', '否', '否', '否', '否', '否', '否', '否', '2026-09-16 20:22:09');
INSERT INTO `galaxy_levels` VALUES (22, '星系 22', '58_39627595209249257.png', '是', '是', '未选择', '否', '是', '是', '未选择', '未选择', '否', '是', '否', '否', '否', '2026-09-16 20:44:18');
INSERT INTO `galaxy_levels` VALUES (23, '星系 23', '65_39627559364724989.png', '是', '是', '未选择', '否', '否', '是', '是', '否', '是', '否', '否', '否', '否', '2026-09-16 20:44:32');
INSERT INTO `galaxy_levels` VALUES (24, '星系 24', '99_39627595272163162.png', '是', '是', '未选择', '否', '否', '是', '否', '是', '否', '否', '否', '否', '否', '2026-09-16 20:57:59');
INSERT INTO `galaxy_levels` VALUES (25, '星系 25', '109_39627595234413762.png', '是', '是', '未选择', '是', '未选择', '未选择', '未选择', '未选择', '否', '否', '否', '否', '否', '2026-09-16 20:58:10');
INSERT INTO `galaxy_levels` VALUES (26, '星系 26', '110_39627559326976619.png', '否', '未选择', '未选择', '未选择', '未选择', '未选择', '未选择', '未选择', '未选择', '未选择', '未选择', '未选择', '未选择', '2026-09-16 20:14:30');
INSERT INTO `galaxy_levels` VALUES (27, '星系 27', '0156m017_8807_0.97.png', '是', '否', '是', '未选择', '未选择', '未选择', '未选择', '未选择', '否', '否', '否', '否', '否', '2026-09-16 20:58:32');
INSERT INTO `galaxy_levels` VALUES (28, '星系 28', '163_39627589186229441.png', '是', '是', '未选择', '否', '是', '否', '未选择', '未选择', '否', '否', '否', '否', '否', '2026-09-16 20:59:35');
INSERT INTO `galaxy_levels` VALUES (29, '星系 29', '250_39627619230028990.png', '是', '是', '未选择', '否', '否', '是', '否', '是', '否', '否', '否', '否', '否', '2026-09-16 20:59:51');
INSERT INTO `galaxy_levels` VALUES (30, '星系 30', '305_39627583314204207.png', '是', '否', '是', '未选择', '未选择', '未选择', '未选择', '未选择', '否', '否', '否', '否', '否', '2026-09-16 21:00:57');
INSERT INTO `galaxy_levels` VALUES (31, '星系 31', '314_39627619221636421.png', '是', '是', '未选择', '否', '否', '是', '是', '是', '否', '否', '否', '否', '否', '2026-09-16 21:01:46');
INSERT INTO `galaxy_levels` VALUES (32, '星系 32', '354_39627577253432895.png', '是', '是', '未选择', '是', '未选择', '未选择', '未选择', '未选择', '否', '否', '否', '否', '否', '2026-09-16 21:01:58');
INSERT INTO `galaxy_levels` VALUES (33, '星系 33', '378_39627553421394845.png', '是', '是', '未选择', '否', '否', '是', '否', '是', '否', '否', '否', '否', '否', '2026-09-16 21:02:12');
INSERT INTO `galaxy_levels` VALUES (34, '星系 34', '381_39627631217349624.png', '是', '是', '未选择', '否', '否', '是', '是', '否', '是', '否', '否', '否', '否', '2026-09-16 21:02:26');
INSERT INTO `galaxy_levels` VALUES (35, '星系 35', '431_39627595230219479.png', '是', '是', '未选择', '否', '否', '是', '否', '否', '否', '否', '否', '否', '否', '2026-09-16 18:55:01');
INSERT INTO `galaxy_levels` VALUES (36, '星系 36', '576_39627631225736144.png', '是', '是', '未选择', '否', '否', '是', '是', '是', '否', '否', '否', '否', '否', '2026-09-16 18:53:29');

SET FOREIGN_KEY_CHECKS = 1;
