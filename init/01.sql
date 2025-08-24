CREATE DATABASE IF NOT EXISTS `ratings_dev`;
GRANT ALL ON `ratings_dev`.* TO 'ratings'@'%';
CREATE DATABASE IF NOT EXISTS `ratings_test`;
GRANT ALL ON `ratings_test`.* TO 'ratings'@'%';