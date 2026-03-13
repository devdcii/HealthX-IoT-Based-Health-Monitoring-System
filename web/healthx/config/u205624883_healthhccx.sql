-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Feb 04, 2026 at 04:35 PM
-- Server version: 11.8.3-MariaDB-log
-- PHP Version: 7.2.34

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `u205624883_healthhccx`
--

-- --------------------------------------------------------

--
-- Table structure for table `admin`
--

CREATE TABLE `admin` (
  `id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `admin`
--

INSERT INTO `admin` (`id`, `username`, `password`, `created_at`) VALUES
(1, 'admin', '123456', '2026-02-04 13:46:40'),
(3, 'healthxhcc@gmail.com', '123456', '2025-12-28 14:10:11'),
(4, 'healthx@gmail.com', '$2y$10$CqDRePVhYWPT9L.xJIQVJ.150on.aHuz1xJFvrlWZHiR/T1lLMBnO', '2025-12-29 18:12:16');

-- --------------------------------------------------------

--
-- Table structure for table `contact_inquiries`
--

CREATE TABLE `contact_inquiries` (
  `id` int(11) NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `subject` varchar(500) NOT NULL,
  `message` text NOT NULL,
  `status` enum('new','read','responded') DEFAULT 'new',
  `notification_viewed` tinyint(1) DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `contact_inquiries`
--

INSERT INTO `contact_inquiries` (`id`, `full_name`, `email`, `phone`, `subject`, `message`, `status`, `notification_viewed`, `created_at`, `updated_at`) VALUES
(4, 'CIi', 'digmanchristian0@gmail.com', NULL, 'Order', 'Do you have any kind of this?', 'responded', 1, '2025-11-17 00:26:12', '2026-02-02 11:35:44'),
(12, 'Cii', 'digmanchristian0@gmail.com', NULL, 'Inquire', 'Hello', 'new', 1, '2026-02-02 11:38:16', '2026-02-02 11:39:10'),
(13, 'Test', 'digmanchristian0@gmail.com', NULL, 'Inquire', 'Hello World', 'responded', 1, '2026-02-02 11:38:53', '2026-02-02 13:33:13'),
(14, 'ciicii', 'digmanchristian0@gmail.com', NULL, 'Hi', 'Hello World', 'new', 1, '2026-02-04 15:03:42', '2026-02-04 15:03:52'),
(15, 'ChanTest', 'digmanchristian0@gmail.com', NULL, 'Hey hi', 'Hello World', 'new', 1, '2026-02-04 15:48:04', '2026-02-04 15:48:12'),
(16, 'Depota', 'digmanchristian0@gmail.com', NULL, 'Hello', 'Hello World', 'new', 1, '2026-02-04 23:55:02', '2026-02-04 23:55:11');

-- --------------------------------------------------------

--
-- Table structure for table `health_readings`
--

CREATE TABLE `health_readings` (
  `id` int(11) NOT NULL,
  `worker_email` varchar(255) NOT NULL,
  `user_email` varchar(255) NOT NULL,
  `patient_name` varchar(255) NOT NULL,
  `weight` decimal(5,2) NOT NULL,
  `height` decimal(5,2) NOT NULL,
  `bmi` decimal(4,2) NOT NULL,
  `heart_rate` int(11) NOT NULL,
  `spo2` int(11) NOT NULL,
  `temperature` decimal(4,2) NOT NULL,
  `systolic` int(11) NOT NULL,
  `diastolic` int(11) NOT NULL,
  `timestamp` datetime NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `health_readings`
--

INSERT INTO `health_readings` (`id`, `worker_email`, `user_email`, `patient_name`, `weight`, `height`, `bmi`, `heart_rate`, `spo2`, `temperature`, `systolic`, `diastolic`, `timestamp`, `created_at`) VALUES
(1, 'healthx@gmail.com', 'chanchan@test.com', 'ChanChan', 0.00, 170.00, 23.20, 80, 90, 35.00, 120, 80, '2026-01-07 01:15:13', '2026-01-06 17:15:14');

-- --------------------------------------------------------

--
-- Table structure for table `health_readings_backup`
--

CREATE TABLE `health_readings_backup` (
  `id` int(11) NOT NULL DEFAULT 0,
  `worker_email` varchar(255) NOT NULL,
  `patient_name` varchar(255) NOT NULL,
  `weight` decimal(5,2) NOT NULL,
  `height` decimal(5,2) NOT NULL,
  `bmi` decimal(4,2) NOT NULL,
  `heart_rate` int(11) NOT NULL,
  `spo2` int(11) NOT NULL,
  `temperature` decimal(4,2) NOT NULL,
  `systolic` int(11) NOT NULL,
  `diastolic` int(11) NOT NULL,
  `timestamp` datetime NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `notification_viewed` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `password`, `created_at`, `updated_at`, `notification_viewed`) VALUES
(3, 'ChanChan', 'chanchan@test.com', '$2y$10$AyDCm77j.WUBKQFsJ6Xl8.hGofcbmvl2SMtPqBdCFRiDyHx9ny6Na', '2026-01-06 16:33:12', '2026-02-02 07:19:02', 1),
(4, 'HealthWorker', 'healthworker@gmail.com', '$2y$10$JqrBhWel2znQ3jN/FjuMQe4rNs5kEcEqFW.5E0ddiFPU9yL5t1ZHu', '2026-01-11 04:27:00', '2026-02-02 07:19:02', 1),
(33, 'Ronnel', 'ronneldeang1736@gmail.com', '$2y$10$45JWcFM28l.vnMpESE/wfeUGIjMXfRzpPT5D1PQiPc0mO8aBjMgRm', '2026-02-03 06:12:36', '2026-02-04 13:46:47', 1),
(36, 'Matt', 'matt@gmail.com', '$2y$10$GhPUMCH4N02.4MDxq/Mztu32y5cHBfjyf56WzjYSWojJ00tWDmjdi', '2026-02-04 03:00:26', '2026-02-04 03:49:43', 1),
(39, 'Joseph', 'joseph@test.com', '$2y$10$zmnlDFqdTrmenMtytRN0KeVtldn7FOcb0rLXCdfOVlWf08sXN5xDu', '2026-02-04 03:29:16', '2026-02-04 03:49:43', 1),
(51, 'Same', 'error@gmail.com', '$2y$10$sDTURmYVduT2Xew9F.uC6eDm9/BA5yOwAG2qHKe7m9sE5ipw0Ea1.', '2026-02-04 15:49:03', '2026-02-04 15:49:18', 1),
(52, 'Depota', 'digmanchristian0@gmail.com', '$2y$10$sdBLd1FzWOlBQjv9XnGbZOKlM101Wcq33SGUP.jLAA4zmnlRxDSZK', '2026-02-04 15:56:25', '2026-02-04 15:56:41', 1),
(53, 'Changgala', 'changgala@gmail.com', '$2y$10$JO8brbEHhzV0vpachX9NTeqjwp1PGcaU5Q8sWJme0vMiPtB9577zS', '2026-02-04 16:14:54', '2026-02-04 16:16:28', 1);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admin`
--
ALTER TABLE `admin`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Indexes for table `contact_inquiries`
--
ALTER TABLE `contact_inquiries`
  ADD PRIMARY KEY (`id`),
  ADD KEY `status_idx` (`status`),
  ADD KEY `created_at_idx` (`created_at`);

--
-- Indexes for table `health_readings`
--
ALTER TABLE `health_readings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `worker_email` (`worker_email`),
  ADD KEY `user_email` (`user_email`),
  ADD KEY `patient_name` (`patient_name`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `idx_email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admin`
--
ALTER TABLE `admin`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `contact_inquiries`
--
ALTER TABLE `contact_inquiries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `health_readings`
--
ALTER TABLE `health_readings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=54;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
