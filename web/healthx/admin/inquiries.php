<?php
// inquiries.php - FIXED VERSION with proper timezone handling
require_once __DIR__ . '/admin_auth.php';
require_once('../config/dbcon.php');

// Include PHPMailer (keep as is)
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require '../vendor/autoload.php';
date_default_timezone_set('Asia/Manila');

// Handle AJAX request to mark notifications as viewed (no changes needed)
if(isset($_POST['mark_viewed']) && isset($_POST['notification_ids'])) {
    $ids = json_decode($_POST['notification_ids'], true);
    if(is_array($ids) && count($ids) > 0) {
        $placeholders = str_repeat('?,', count($ids) - 1) . '?';
        $stmt = $conn->prepare("UPDATE contact_inquiries SET notification_viewed = 1 WHERE id IN ($placeholders)");
        $types = str_repeat('i', count($ids));
        $stmt->bind_param($types, ...$ids);
        $stmt->execute();
        $stmt->close();
    }
    echo json_encode(['success' => true]);
    exit;
}

// Handle email reply submission (no changes needed - keep your PHPMailer code)
if(isset($_POST['send_reply'])) {
    $inquiry_id = intval($_POST['inquiry_id']);
    $customer_email = $_POST['customer_email'];
    $customer_name = $_POST['customer_name'];
    $reply_subject = $_POST['reply_subject'];
    $reply_message = $_POST['reply_message'];
    
    $mail = new PHPMailer(true);
    
    try {
        // [Keep all your PHPMailer configuration exactly as is]
        $mail->isSMTP();
        $mail->Host       = 'smtp.gmail.com';
        $mail->SMTPAuth   = true;
        $mail->Username   = 'healthxinnovation@gmail.com';
        $mail->Password   = 'dgun hgoz xmax ejxq';
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
        $mail->Port       = 587;
        
        $mail->setFrom('healthxinnovation@gmail.com', 'HealthX Support');
        $mail->addAddress($customer_email, $customer_name);
        $mail->addReplyTo('healthxinnovation@gmail.com', 'HealthX Support');
        
        $mail->isHTML(true);
        $mail->Subject = $reply_subject;
        $mail->CharSet = 'UTF-8';
        
        // [Keep your entire email body HTML template]
        $mail->Body = "
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset='UTF-8'>
            <style>
                body { 
                    font-family: 'Segoe UI', Arial, sans-serif; 
                    line-height: 1.6; 
                    color: #0f2336;
                    margin: 0;
                    padding: 0;
                    background-color: #f4f7fa;
                }
                .email-wrapper {
                    max-width: 600px;
                    margin: 20px auto;
                    background: #ffffff;
                    border-radius: 12px;
                    overflow: hidden;
                    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
                }
                .header { 
                    background: linear-gradient(135deg, #1848a0, #0d3575); 
                    color: white; 
                    padding: 40px 30px; 
                    text-align: center;
                }
                .header h1 {
                    margin: 0;
                    font-size: 28px;
                    font-weight: 700;
                    letter-spacing: 1px;
                }
                .header p {
                    margin: 10px 0 0 0;
                    font-size: 14px;
                    opacity: 0.9;
                }
                .content { 
                    background: #ffffff; 
                    padding: 40px 30px;
                }
                .content p {
                    margin: 0 0 15px 0;
                    color: #0f2336;
                }
                .message-box {
                    background: #f0f4f8;
                    padding: 25px;
                    border-left: 4px solid #1848a0;
                    margin: 25px 0;
                    border-radius: 8px;
                }
                .divider {
                    border: none;
                    border-top: 2px solid #1848a0;
                    margin: 30px 0;
                }
                .contact-info {
                    background: #f9fafb;
                    padding: 20px;
                    border-radius: 8px;
                    margin: 20px 0;
                }
                .contact-info p {
                    font-size: 14px;
                    color: #4a5568;
                    margin: 5px 0;
                }
                .contact-info strong {
                    color: #0f2336;
                }
                .signature {
                    margin-top: 30px;
                }
                .footer { 
                    text-align: center; 
                    padding: 30px; 
                    color: #718096; 
                    font-size: 12px;
                    background: #f7fafc;
                }
                .footer p {
                    margin: 5px 0;
                }
            </style>
        </head>
        <body>
            <div class='email-wrapper'>
                <div class='header'>
                    <h1>HealthX</h1>
                    <p>IoT Based Health Monitoring System</p>
                </div>
                <div class='content'>
                    <p>Dear <strong>" . htmlspecialchars($customer_name) . "</strong>,</p>
                    <p>Thank you for contacting HealthX. We appreciate your inquiry and are pleased to respond.</p>
                    
                    <div class='message-box'>
                        " . nl2br(htmlspecialchars($reply_message)) . "
                    </div>
                    
                    <p>If you have any further questions or concerns, please don't hesitate to contact us.</p>
                    
                    <div class='signature'>
                        <p style='margin-bottom: 5px;'>Best regards,</p>
                        <p style='margin-top: 5px;'><strong>The HealthX Support Team</strong></p>
                    </div>
                    
                    <hr class='divider'>
                    
                    <div class='contact-info'>
                        <p><strong>Contact Information:</strong></p>
                        <p>📧 Email: healthxinnovation@gmail.com</p>
                        <p>📱 Phone: +63 999 392 1960</p>
                        <p>📱 Phone: +63 933 819 7734</p>
                        <p>📱 Phone: +63 908 968 8524</p>
                        <p>📱 Phone: +63 999 187 0384</p>
                        <p>📘 Facebook: https://www.facebook.com/share/1CRJxXa86g/</p>
                        <p>🕒 Support Hours: Monday - Friday, 7:00 AM - 5:00 PM (PHT)</p>
                    </div>
                </div>
                <div class='footer'>
                    <p>&copy; 2025 HealthX. All Rights Reserved.</p>
                    <p>Committed to Excellence in Remote Patient Monitoring</p>
                </div>
            </div>
        </body>
        </html>
        ";
        
        $mail->AltBody = "Dear " . $customer_name . ",\n\n"
            . "Thank you for contacting HealthX.\n\n"
            . strip_tags($reply_message) . "\n\n"
            . "If you have any further questions, please contact us at support@healthx.com\n\n"
            . "Best regards,\n"
            . "The HealthX Support Team";
        
        $mail->send();
        
        $stmt = $conn->prepare("UPDATE contact_inquiries SET status = 'responded', updated_at = NOW() WHERE id = ?");
        $stmt->bind_param("i", $inquiry_id);
        $stmt->execute();
        $stmt->close();
        
        $_SESSION['success_message'] = "Reply sent successfully to " . htmlspecialchars($customer_email);
        
    } catch (Exception $e) {
        $_SESSION['error_message'] = "Failed to send email. Error: " . $mail->ErrorInfo;
        error_log("PHPMailer Error: " . $mail->ErrorInfo);
    }
    
    header("Location: inquiries.php");
    exit;
}

// Handle status update (no changes needed)
if(isset($_POST['update_status'])) {
    $id = intval($_POST['inquiry_id']);
    $status = $_POST['status'];
    $stmt = $conn->prepare("UPDATE contact_inquiries SET status = ?, updated_at = NOW() WHERE id = ?");
    $stmt->bind_param("si", $status, $id);
    $stmt->execute();
    $stmt->close();
    $_SESSION['success_message'] = "Status updated successfully";
    header('Location: inquiries.php');
    exit;
}

// Handle delete (no changes needed)
if(isset($_POST['delete_inquiry'])) {
    $id = intval($_POST['inquiry_id']);
    $stmt = $conn->prepare("DELETE FROM contact_inquiries WHERE id = ?");
    $stmt->bind_param("i", $id);
    $stmt->execute();
    $stmt->close();
    $_SESSION['success_message'] = "Inquiry deleted successfully";
    header('Location: inquiries.php');
    exit;
}

// ✅ FIXED: Get inquiries with PH time conversion
$inquiries = [];
$result = $conn->query("
    SELECT 
        id,
        full_name,
        email,
        phone,
        subject,
        message,
        status,
        notification_viewed,
        DATE_ADD(created_at, INTERVAL 8 HOUR) as created_at,
        DATE_ADD(updated_at, INTERVAL 8 HOUR) as updated_at
    FROM contact_inquiries 
    ORDER BY created_at DESC
");
while($row = $result->fetch_assoc()) {
    $inquiries[] = $row;
}

$totalInquiries = count($inquiries);
$newInquiries = 0;
$readInquiries = 0;
$respondedInquiries = 0;

foreach($inquiries as $inq) {
    if($inq['status'] === 'new') $newInquiries++;
    elseif($inq['status'] === 'read') $readInquiries++;
    elseif($inq['status'] === 'responded') $respondedInquiries++;
}

// ✅ FIXED: Get notifications with PH time
$notifications_result = $conn->query("
    SELECT 
        id, 
        full_name, 
        email, 
        subject, 
        DATE_ADD(created_at, INTERVAL 8 HOUR) as created_at, 
        notification_viewed
    FROM contact_inquiries
    WHERE status = 'new'
    ORDER BY created_at DESC
");
$notifications = [];
while($row = $notifications_result->fetch_assoc()) {
    $notifications[] = $row;
}

$unviewedCount = $conn->query("
    SELECT COUNT(*) as count
    FROM contact_inquiries 
    WHERE status = 'new' AND notification_viewed = 0
")->fetch_assoc()['count'];

$admin_username = $_SESSION['admin_username'] ?? 'Admin';
?>

<!-- Keep ALL your existing HTML code exactly as is - no changes needed -->

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HealthX - Contact Inquiries</title>
    <link rel="icon" type="image/png" href="../images/logo.png">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="../css/admin_style.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        /* Inquiries Page Specific Modal Styling */
        #viewModal .modal-container,
        #replyModal .modal-container {
            max-width: 700px;
        }
        
        #replyModal .form-group {
            margin-bottom: 1.5rem;
        }
        
        #replyModal .form-group label {
            display: block;
            margin-bottom: 0.5rem;
            font-weight: 600;
            color: var(--text-primary);
        }
        
        #replyModal .form-group input,
        #replyModal .form-group textarea,
        #viewModal .form-group select {
            width: 100%;
            padding: 0.8rem;
            border: 2px solid var(--gray-200);
            border-radius: 8px;
            font-family: inherit;
            font-size: 0.95rem;
            transition: border-color 0.3s ease;
        }
        
        #replyModal .form-group input:focus,
        #replyModal .form-group textarea:focus,
        #viewModal .form-group select:focus {
            outline: none;
            border-color: var(--primary);
        }
        
        #replyModal .form-group textarea {
            resize: vertical;
            min-height: 150px;
        }
        
        #replyModal .form-group small {
            display: block;
            margin-top: 0.5rem;
            color: var(--text-secondary);
            font-size: 0.85rem;
        }
    </style>
</head>
<body>
    <aside class="sidebar" id="sidebar">
        <div class="sidebar-header">
            <div class="logo">
                <img src="../images/flogo.png" alt="HealthX Logo" class="logo-img" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                <div class="logo-icon" style="display: none;"><i class="fas fa-heartbeat"></i></div>
                <div class="logo-content"><span class="logo-text">HealthX</span></div>
            </div>
            <button class="sidebar-toggle" id="sidebarToggle"><i class="fas fa-angle-left"></i></button>
        </div>
        <nav class="sidebar-nav">
            <div class="nav-section">
                <span class="nav-section-title">Main</span>
                <a href="dashboard.php" class="nav-item"><div class="nav-icon"><i class="fas fa-chart-line"></i></div><span class="nav-text">Dashboard</span></a>
                <a href="patients.php" class="nav-item"><div class="nav-icon"><i class="fas fa-users"></i></div><span class="nav-text">Patients</span></a>
                <a href="health_workers.php" class="nav-item"><div class="nav-icon"><i class="fas fa-user-md"></i></div><span class="nav-text">Health Workers</span></a>
            </div>
            <div class="nav-section">
                <span class="nav-section-title">Data</span>
                <a href="readings.php" class="nav-item"><div class="nav-icon"><i class="fas fa-heartbeat"></i></div><span class="nav-text">Health Readings</span></a>
                <a href="alerts.php" class="nav-item"><div class="nav-icon"><i class="fas fa-exclamation-triangle"></i></div><span class="nav-text">Critical Alerts</span></a>
                <a href="inquiries.php" class="nav-item active"><div class="nav-icon"><i class="fas fa-inbox"></i></div><span class="nav-text">Inquiries</span></a>
            </div>
        </nav>
        <div class="sidebar-footer">
            <a href="logout.php" class="logout-btn"><i class="fas fa-sign-out-alt"></i><span class="logout-text">Logout</span></a>
        </div>
    </aside>

    <main class="main-content">
        <header class="top-bar">
            <div class="top-bar-left">
                <button class="mobile-toggle" id="menuToggle"><i class="fas fa-bars"></i></button>
                <div class="page-title">
                    <h1>Contact Inquiries</h1>
                    <p class="subtitle">Manage customer inquiries and messages</p>
                </div>
            </div>
            <div class="top-bar-right">
                <div class="quick-stats">
                    <div class="quick-stat"><i class="fas fa-clock"></i><span><?php echo date('l, F j, Y g:i A'); ?></span></div>
                    <button class="notification-btn" id="notificationBtn" aria-label="Notifications">
                        <i class="fas fa-bell"></i>
                        <?php if($unviewedCount > 0): ?>
                        <span class="badge"><?php echo $unviewedCount; ?></span>
                        <?php endif; ?>
                    </button>
                </div>
            </div>
        </header>

        <!-- Notifications Dropdown -->
        <div class="notifications-dropdown" id="notificationsDropdown">
            <div class="notifications-header">
                <h3>New Inquiries</h3>
                <button class="close-notifications" id="closeNotifications" aria-label="Close notifications">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <div class="notifications-body">
                <?php if(count($notifications) > 0): ?>
                    <?php foreach($notifications as $notif): ?>
                        <div class="notification-item <?php echo $notif['notification_viewed'] ? 'viewed' : 'unviewed'; ?>" data-id="<?php echo $notif['id']; ?>">
                            <div class="notification-icon">
                                <i class="fas fa-envelope"></i>
                            </div>
                            <div class="notification-content">
                                <h4><?php echo htmlspecialchars($notif['full_name']); ?></h4>
                                <p><?php echo htmlspecialchars($notif['subject']); ?></p>
                                <span class="notification-time"><?php echo date('M d, g:i A', strtotime($notif['created_at'])); ?></span>
                            </div>
                            <?php if(!$notif['notification_viewed']): ?>
                            <div class="notification-badge-dot"></div>
                            <?php endif; ?>
                        </div>
                    <?php endforeach; ?>
                <?php else: ?>
                    <div class="notification-empty">
                        <i class="fas fa-bell-slash"></i>
                        <p>No new inquiries</p>
                    </div>
                <?php endif; ?>
            </div>
        </div>

        <div class="dashboard-content">
            <!-- Success/Error Messages as JavaScript Alerts -->
            <?php if(isset($_SESSION['success_message'])): ?>
                <script>
                    alert('<?php echo addslashes($_SESSION['success_message']); ?>');
                </script>
                <?php unset($_SESSION['success_message']); ?>
            <?php endif; ?>
            
            <?php if(isset($_SESSION['error_message'])): ?>
                <script>
                    alert('<?php echo addslashes($_SESSION['error_message']); ?>');
                </script>
                <?php unset($_SESSION['error_message']); ?>
            <?php endif; ?>

            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-header"><div class="stat-icon"><i class="fas fa-inbox"></i></div></div>
                    <div class="stat-body">
                        <h3>Total Inquiries</h3>
                        <div class="stat-value"><?php echo number_format($totalInquiries); ?></div>
                        <p class="stat-description">All time</p>
                    </div>
                    <div class="stat-footer"><a href="#inquiries-table">View all <i class="fas fa-arrow-right"></i></a></div>
                </div>

                <div class="stat-card">
                    <div class="stat-header"><div class="stat-icon"><i class="fas fa-envelope"></i></div></div>
                    <div class="stat-body">
                        <h3>New Inquiries</h3>
                        <div class="stat-value"><?php echo number_format($newInquiries); ?></div>
                        <p class="stat-description">Unread messages</p>
                    </div>
                    <div class="stat-footer"><a href="#inquiries-table">View details <i class="fas fa-arrow-right"></i></a></div>
                </div>

                <div class="stat-card">
                    <div class="stat-header"><div class="stat-icon"><i class="fas fa-envelope-open"></i></div></div>
                    <div class="stat-body">
                        <h3>Read Inquiries</h3>
                        <div class="stat-value"><?php echo number_format($readInquiries); ?></div>
                        <p class="stat-description">Pending response</p>
                    </div>
                    <div class="stat-footer"><a href="#inquiries-table">View data <i class="fas fa-arrow-right"></i></a></div>
                </div>

                <div class="stat-card">
                    <div class="stat-header"><div class="stat-icon"><i class="fas fa-check-circle"></i></div></div>
                    <div class="stat-body">
                        <h3>Responded</h3>
                        <div class="stat-value"><?php echo number_format($respondedInquiries); ?></div>
                        <p class="stat-description">Completed</p>
                    </div>
                    <div class="stat-footer"><a href="#inquiries-table">Details <i class="fas fa-arrow-right"></i></a></div>
                </div>
            </div>

            <div class="charts-container">
                <div class="chart-medium">
                    <div class="chart-card">
                        <div class="chart-header"><div><h2><i class="fas fa-chart-pie"></i> Status Distribution</h2><p>Inquiries by status</p></div></div>
                        <div class="chart-body"><canvas id="statusChart"></canvas></div>
                    </div>
                </div>
                <div class="chart-medium">
                    <div class="chart-card">
                        <div class="chart-header"><div><h2><i class="fas fa-chart-bar"></i> Response Rate</h2><p>Performance metrics</p></div></div>
                        <div class="chart-body"><canvas id="responseChart"></canvas></div>
                    </div>
                </div>
            </div>

            <div class="table-section" id="inquiries-table">
                <div class="section-header"><h2><i class="fas fa-list"></i> All Inquiries</h2></div>
                <div class="table-container">
                    <table class="data-table">
                        <thead>
                            <tr><th>Name</th><th>Email</th><th>Subject</th><th>Message</th><th>Status</th><th>Date</th><th>Actions</th></tr>
                        </thead>
                        <tbody>
                            <?php foreach($inquiries as $inquiry): ?>
                            <tr>
                                <td><?php echo htmlspecialchars($inquiry['full_name']); ?></td>
                                <td><?php echo htmlspecialchars($inquiry['email']); ?></td>
                                <td><?php echo htmlspecialchars($inquiry['subject']); ?></td>
                                <td><span title="<?php echo htmlspecialchars($inquiry['message']); ?>"><?php echo htmlspecialchars(substr($inquiry['message'], 0, 50)); ?>...</span></td>
                                <td>
                                    <?php
                                    $badgeClass = 'elevated';
                                    if($inquiry['status'] === 'read') $badgeClass = 'low';
                                    if($inquiry['status'] === 'responded') $badgeClass = 'normal';
                                    ?>
                                    <span class="reading-category <?php echo $badgeClass; ?>"><?php echo ucfirst($inquiry['status']); ?></span>
                                </td>
                                <td><?php echo date('M d, Y g:i A', strtotime($inquiry['created_at'])); ?></td>
                                <td>
                                    <div class="action-buttons" style="display:flex;gap:0.5rem;align-items:center;justify-content:flex-end;">
                                        <button class="icon-btn btn-view" 
                                                data-inquiry='<?php echo htmlspecialchars(json_encode($inquiry), ENT_QUOTES); ?>'
                                                onclick="viewInquiry(this, event)"
                                                title="View inquiry"
                                                aria-label="View inquiry">
                                            <i class="fas fa-eye"></i>
                                        </button>
                                        <button class="icon-btn btn-edit"
                                                data-inquiry='<?php echo htmlspecialchars(json_encode($inquiry), ENT_QUOTES); ?>'
                                                onclick="replyInquiry(this, event)"
                                                title="Reply to inquiry"
                                                aria-label="Reply to inquiry">
                                            <i class="fas fa-reply"></i>
                                        </button>
                                        <button class="icon-btn btn-delete"
                                                data-inquiry='<?php echo htmlspecialchars(json_encode($inquiry), ENT_QUOTES); ?>'
                                                onclick="deleteInquiry(this, event)"
                                                title="Delete inquiry"
                                                aria-label="Delete inquiry">
                                            <i class="fas fa-trash"></i>
                                        </button>
                                    </div>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </main>

    <!-- View Inquiry Modal -->
    <div class="modal-overlay" id="viewModal">
        <div class="modal-container">
            <div class="modal-header">
                <h2><i class="fas fa-envelope-open"></i> Inquiry Details</h2>
                <button class="modal-close" onclick="closeInquiryModal()"><i class="fas fa-times"></i></button>
            </div>
            <div class="modal-body" id="inquiryDetails"></div>
            <div class="modal-footer" id="inquiryActions"></div>
        </div>
    </div>

    <!-- Reply Inquiry Modal -->
    <div class="modal-overlay" id="replyModal">
        <div class="modal-container">
            <div class="modal-header">
                <h2><i class="fas fa-reply"></i> Reply to Inquiry</h2>
                <button class="modal-close" onclick="closeReplyModal()"><i class="fas fa-times"></i></button>
            </div>
            <div class="modal-body">
                <form method="POST" id="replyForm">
                    <input type="hidden" name="inquiry_id" id="replyInquiryId">
                    <input type="hidden" name="customer_email" id="replyCustomerEmail">
                    <input type="hidden" name="customer_name" id="replyCustomerName">
                    
                    <div style="margin-bottom: 1.5rem; padding: 1rem; background: var(--gray-50); border-radius: 8px;">
                        <strong style="color: var(--text-primary);">To:</strong>
                        <p id="replyToInfo" style="margin: 0.5rem 0 0 0; color: var(--text-secondary);"></p>
                    </div>
                    
                    <div class="form-group">
                        <label>
                            <i class="fas fa-heading"></i> Subject
                        </label>
                        <input type="text" name="reply_subject" id="replySubject" required placeholder="Enter subject..." style="width:100%;padding:0.8rem;border:2px solid var(--gray-200);border-radius:8px;font-family:inherit;font-size:0.95rem;">
                    </div>
                    
                    <div class="form-group">
                        <label>
                            <i class="fas fa-comment-dots"></i> Your Reply Message
                        </label>
                        <textarea name="reply_message" id="replyMessage" required placeholder="Type your reply message here..." style="width:100%;padding:0.8rem;border:2px solid var(--gray-200);border-radius:8px;font-family:inherit;font-size:0.95rem;resize:vertical;min-height:150px;"></textarea>
                        <small style="display:block;margin-top:0.5rem;color:var(--text-secondary);font-size:0.85rem;">
                            <i class="fas fa-info-circle"></i> This message will be sent via email with professional formatting.
                        </small>
                    </div>
                    
                    <div style="display: flex; gap: 1rem;">
                        <button type="submit" name="send_reply" class="modal-btn modal-btn-primary" style="flex: 1;">
                            <i class="fas fa-paper-plane"></i> Send Reply
                        </button>
                        <button type="button" onclick="closeReplyModal()" class="modal-btn modal-btn-secondary" style="flex: 1;">
                            <i class="fas fa-times"></i> Cancel
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script>
        const statusData = {
            new: <?php echo $newInquiries; ?>,
            read: <?php echo $readInquiries; ?>,
            responded: <?php echo $respondedInquiries; ?>
        };
    </script>
    <script src="../js/admin_script.js"></script>
    <script src="../js/inquiries.js"></script>
</body>
</html>