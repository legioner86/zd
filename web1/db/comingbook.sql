CREATE TABLE `messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `login_sender` varchar(35) NOT NULL,
  `add_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `message` text NOT NULL,
  `ip` varchar(15) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ls` (`login_sender`),
  KEY `ad` (`add_date`)
);