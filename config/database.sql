CREATE DATABASE IF NOT EXISTS `fb-clone`;
USE `fb-clone`;

CREATE TABLE IF NOT EXISTS `user` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `birthdate` varchar(10) DEFAULT NULL, # yyyy-mm-dd
  `photo` varchar(256) DEFAULT NULL,
  `username` varchar(32) NOT NULL,
  `password` varchar(256) NOT NULL,
  `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE (`username`)
);

CREATE TABLE IF NOT EXISTS `user_friendship` (
  `user_a_id` int(11) NOT NULL,
  `user_b_id` int(11) NOT NULL,
  PRIMARY KEY (`user_a_id`, `user_b_id`),
  CONSTRAINT `friendship_a` FOREIGN KEY (`user_a_id`) REFERENCES `user`(`id`) ON DELETE CASCADE,
  CONSTRAINT `friendship_b` FOREIGN KEY (`user_b_id`) REFERENCES `user`(`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `user_friendship_request` (
  `requester_id` int(11) NOT NULL,
  `requested_id` int(11) NOT NULL,
  PRIMARY KEY (`requester_id`, `requested_id`),
  CONSTRAINT `friendship_requester` FOREIGN KEY (`requester_id`) REFERENCES `user`(`id`) ON DELETE CASCADE,
  CONSTRAINT `friendship_requested` FOREIGN KEY (`requested_id`) REFERENCES `user`(`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `user_blocking` (
  `blocker_id` int(11) NOT NULL,
  `blocked_id` int(11) NOT NULL,
  PRIMARY KEY (`blocker_id`, `blocked_id`),
  CONSTRAINT `user_blocker` FOREIGN KEY (`blocker_id`) REFERENCES `user`(`id`) ON DELETE CASCADE,
  CONSTRAINT `user_blocked` FOREIGN KEY (`blocked_id`) REFERENCES `user`(`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `post` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `author_id` int(11) NOT NULL,
  `content` varchar(4096) DEFAULT NULL,
  `picture` varchar(256) DEFAULT NULL,
  `is_public` boolean DEFAULT 1,
  PRIMARY KEY (`id`),
  CONSTRAINT `post_authorship` FOREIGN KEY (`author_id`) REFERENCES `user`(`id`) ON DELETE CASCADE,
  CONSTRAINT `post_minimum_content` CHECK (
    `content` IS NOT NULL OR `picture` IS NOT NULL
  )
);

CREATE TABLE IF NOT EXISTS `feed_post` (
  `post_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`post_id`),
  CONSTRAINT `feed_post_self` FOREIGN KEY (`post_id`) REFERENCES `post`(`id`) ON DELETE CASCADE,
  CONSTRAINT `feed_post_owner` FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE CASCADE
);

-- Also delete the post 
CREATE TRIGGER `feed_post_deletion`
AFTER DELETE ON `feed_post` FOR EACH ROW
  DELETE FROM `post` WHERE `id`=OLD.`post_id`;

CREATE TABLE IF NOT EXISTS `comment` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `post_id` int(11) NOT NULL,
  `content` varchar(1024) DEFAULT 1,
  PRIMARY KEY (`id`),
  CONSTRAINT `post_commentator` FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE CASCADE,
  CONSTRAINT `post_commented` FOREIGN KEY (`post_id`) REFERENCES `post`(`id`) ON DELETE CASCADE
);

-- The hard approach for deleted user: allows a comment to exist even if the user is deleted.
-- CREATE TRIGGER `unauthored_comment`
-- BEFORE INSERT ON `comment` FOR EACH ROW
-- BEGIN
--   IF (NEW.`user_id` IS NULL) THEN
--     SIGNAL SQLSTATE '99900' SET MESSAGE_TEXT='The comment author can not be NULL';
--   END IF;
-- END;

CREATE TABLE IF NOT EXISTS `comment_answer` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `comment_id` int(11) NOT NULL,
  `content` varchar(1024) DEFAULT 1,
  PRIMARY KEY (`id`),
  CONSTRAINT `comment_commentator` FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE CASCADE,
  CONSTRAINT `comment_commented` FOREIGN KEY (`comment_id`) REFERENCES `comment`(`id`) ON DELETE CASCADE
);

-- The hard approach for deleted user: allows a comment answer to exist even if the user is deleted.
-- CREATE TRIGGER `unauthored_comment_answer`
-- BEFORE INSERT ON `comment_answer` FOR EACH ROW
-- BEGIN
--   IF (NEW.`user_id` IS NULL) THEN
--     SIGNAL SQLSTATE '99900' SET MESSAGE_TEXT='The comment author can not be NULL';
--   END IF;
-- END;

CREATE TABLE IF NOT EXISTS `group` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `creator_id` int(11) NOT NULL,
  `name` varchar(128) NOT NULL,
  `description` varchar(512) NOT NULL DEFAULT '',
  `picture` varchar(256),
  PRIMARY KEY (`id`),
  CONSTRAINT `group_creator` FOREIGN KEY (`creator_id`) REFERENCES `user`(`id`) ON DELETE CASCADE
);

-- The hard approach for deleted creator: keep the group but pass ownership to another member
-- inside a trigger on update that sets the creator_id to NULL. The member should be an admin,
-- otherwise the group is deleted.

CREATE TABLE IF NOT EXISTS `group_post` (
  `post_id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL,
  PRIMARY KEY (`post_id`),
  CONSTRAINT `group_post_self` FOREIGN KEY (`post_id`) REFERENCES `post`(`id`) ON DELETE CASCADE,
  CONSTRAINT `group_post_owner` FOREIGN KEY (`group_id`) REFERENCES `group`(`id`) ON DELETE CASCADE
);

-- Also delete the post
CREATE TRIGGER `group_post_deletion`
AFTER DELETE ON `group_post` FOR EACH ROW
  DELETE FROM `post` WHERE `id`=OLD.`post_id`;

CREATE TABLE IF NOT EXISTS `group_membership` (
  `user_id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL,
  `is_admin` boolean DEFAULT 0,
  PRIMARY KEY (`user_id`, `group_id`),
  CONSTRAINT `membership` FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE CASCADE,
  CONSTRAINT `membership_group` FOREIGN KEY (`group_id`) REFERENCES `group`(`id`) ON DELETE CASCADE
);

-- The hard approach for create a group: also create the creator's membership.
CREATE TRIGGER `group_creation`
AFTER INSERT ON `group` FOR EACH ROW
  INSERT INTO `group_membership` (`user_id`, `group_id`, `is_admin`)
  VALUES (NEW.`creator_id`, NEW.`id`, '1');

CREATE TABLE IF NOT EXISTS `group_blocking` (
  `user_id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL,
  PRIMARY KEY (`user_id`, `group_id`),
  CONSTRAINT `group_blocked_user` FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE CASCADE,
  CONSTRAINT `blocker_group` FOREIGN KEY (`group_id`) REFERENCES `group`(`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `group_membership_request` (
  `user_id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL,
  PRIMARY KEY (`user_id`, `group_id`),
  CONSTRAINT `membership_requester` FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE CASCADE,
  CONSTRAINT `requested_group` FOREIGN KEY (`group_id`) REFERENCES `group`(`id`) ON DELETE CASCADE
);
