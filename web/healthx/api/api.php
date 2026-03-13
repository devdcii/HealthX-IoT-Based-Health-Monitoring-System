<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include 'config/dbcon.php';

// Get request method and data
$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true);

function generateToken() {
    return bin2hex(random_bytes(32));
}

$response = [];

switch($method) {
    case 'POST':
        // User Registration
        if(isset($_GET['action']) && $_GET['action'] == 'register') {
            $username = $input['username'];
            $email = $input['email'];
            $password = md5($input['password']);
            $full_name = $input['full_name'] ?? '';
            $age = $input['age'] ?? null;
            $gender = $input['gender'] ?? '';
            $address = $input['address'] ?? '';
            $contact = $input['contact_number'] ?? '';
            
            // Check if username or email exists
            $check_sql = "SELECT id FROM users WHERE username = ? OR email = ?";
            $check_stmt = $conn->prepare($check_sql);
            $check_stmt->bind_param("ss", $username, $email);
            $check_stmt->execute();
            
            if($check_stmt->get_result()->num_rows > 0) {
                $response = ["success" => false, "message" => "Username or email already exists"];
            } else {
                $sql = "INSERT INTO users (username, email, password, full_name, age, gender, address, contact_number) 
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
                $stmt = $conn->prepare($sql);
                $stmt->bind_param("ssssisss", $username, $email, $password, $full_name, $age, $gender, $address, $contact);
                
                if($stmt->execute()) {
                    $user_id = $conn->insert_id;
                    
                    // Create session token
                    $token = generateToken();
                    $expires = date('Y-m-d H:i:s', strtotime('+7 days'));
                    
                    $token_sql = "INSERT INTO sessions (user_id, session_token, expires_at) VALUES (?, ?, ?)";
                    $token_stmt = $conn->prepare($token_sql);
                    $token_stmt->bind_param("iss", $user_id, $token, $expires);
                    $token_stmt->execute();
                    
                    $response = [
                        "success" => true,
                        "message" => "Registration successful",
                        "token" => $token,
                        "user" => [
                            "id" => $user_id,
                            "username" => $username,
                            "email" => $email,
                            "full_name" => $full_name
                        ]
                    ];
                } else {
                    $response = ["success" => false, "message" => "Registration failed"];
                }
            }
        }
        
        // User Login
        elseif(isset($_GET['action']) && $_GET['action'] == 'user_login') {
            $username = $input['username'];
            $password = md5($input['password']);
            
            $sql = "SELECT id, username, email, full_name, age, gender, address, contact_number 
                    FROM users 
                    WHERE username = ? AND password = ? AND is_active = 1";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("ss", $username, $password);
            $stmt->execute();
            $result = $stmt->get_result();
            
            if($result->num_rows > 0) {
                $user = $result->fetch_assoc();
                
                // Create session token
                $token = generateToken();
                $expires = date('Y-m-d H:i:s', strtotime('+7 days'));
                
                $token_sql = "INSERT INTO sessions (user_id, session_token, expires_at) VALUES (?, ?, ?)";
                $token_stmt = $conn->prepare($token_sql);
                $token_stmt->bind_param("iss", $user['id'], $token, $expires);
                $token_stmt->execute();
                
                $response = [
                    "success" => true,
                    "message" => "Login successful",
                    "token" => $token,
                    "user" => $user
                ];
            } else {
                $response = ["success" => false, "message" => "Invalid credentials"];
            }
        }
        
        // Admin Login (fixed: username=admin, password=admin123)
        elseif(isset($_GET['action']) && $_GET['action'] == 'admin_login') {
            $username = $input['username'];
            $password = md5($input['password']);
            
            $sql = "SELECT id, username FROM admin WHERE username = ? AND password = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("ss", $username, $password);
            $stmt->execute();
            $result = $stmt->get_result();
            
            if($result->num_rows > 0) {
                $admin = $result->fetch_assoc();
                $response = [
                    "success" => true,
                    "message" => "Admin login successful",
                    "admin" => $admin
                ];
            } else {
                $response = ["success" => false, "message" => "Invalid admin credentials"];
            }
        }
        
        // Save Health Record
        elseif(isset($_GET['action']) && $_GET['action'] == 'save_health_record') {
            // Verify token
            $token = $input['token'] ?? '';
            $user_id = $input['user_id'] ?? 0;
            
            // Check if token is valid
            $token_sql = "SELECT user_id FROM sessions WHERE session_token = ? AND expires_at > NOW()";
            $token_stmt = $conn->prepare($token_sql);
            $token_stmt->bind_param("s", $token);
            $token_stmt->execute();
            $token_result = $token_stmt->get_result();
            
            if($token_result->num_rows > 0) {
                // Calculate BMI and status
                $weight = $input['weight'];
                $height = $input['height'];
                $bmi = $weight / (($height/100) * ($height/100));
                
                // Determine BMI category
                if($bmi < 18.5) $bmi_category = 'Underweight';
                elseif($bmi < 25) $bmi_category = 'Normal';
                elseif($bmi < 30) $bmi_category = 'Overweight';
                else $bmi_category = 'Obese';
                
                // Determine health status (simplified logic)
                $health_status = 'Healthy';
                $issues = [];
                
                if($input['heart_rate'] < 60 || $input['heart_rate'] > 100) $issues[] = 'heart';
                if($input['spo2'] < 95) $issues[] = 'oxygen';
                if($bmi_category != 'Normal') $issues[] = 'bmi';
                
                if(count($issues) > 2) $health_status = 'Needs Attention';
                elseif(count($issues) > 0) $health_status = 'Fair';
                
                $sql = "INSERT INTO health_records 
                        (user_id, heart_rate, systolic, diastolic, body_temp, spo2, weight, height, bmi, bmi_category, health_status) 
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                
                $stmt = $conn->prepare($sql);
                $stmt->bind_param(
                    "iiiididddss", 
                    $user_id,
                    $input['heart_rate'],
                    $input['systolic'],
                    $input['diastolic'],
                    $input['body_temp'],
                    $input['spo2'],
                    $input['weight'],
                    $input['height'],
                    $bmi,
                    $bmi_category,
                    $health_status
                );
                
                if($stmt->execute()) {
                    $response = ["success" => true, "message" => "Health record saved"];
                } else {
                    $response = ["success" => false, "message" => "Failed to save record"];
                }
            } else {
                $response = ["success" => false, "message" => "Invalid session"];
            }
        }
        
        break;
        
    case 'GET':
        // Get all users (for admin)
        if(isset($_GET['action']) && $_GET['action'] == 'get_all_users') {
            $sql = "SELECT id, username, email, full_name, age, gender, address, contact_number, created_at 
                    FROM users WHERE is_active = 1";
            $result = $conn->query($sql);
            
            $users = [];
            while($row = $result->fetch_assoc()) {
                $users[] = $row;
            }
            
            $response = ["success" => true, "users" => $users];
        }
        
        // Get user's health records
        elseif(isset($_GET['action']) && $_GET['action'] == 'get_user_records') {
            $user_id = $_GET['user_id'];
            $token = $_GET['token'] ?? '';
            
            // Verify token
            $token_sql = "SELECT user_id FROM sessions WHERE session_token = ? AND expires_at > NOW()";
            $token_stmt = $conn->prepare($token_sql);
            $token_stmt->bind_param("s", $token);
            $token_stmt->execute();
            $token_result = $token_stmt->get_result();
            
            if($token_result->num_rows > 0) {
                $sql = "SELECT * FROM health_records WHERE user_id = ? ORDER BY recorded_at DESC";
                $stmt = $conn->prepare($sql);
                $stmt->bind_param("i", $user_id);
                $stmt->execute();
                $result = $stmt->get_result();
                
                $records = [];
                while($row = $result->fetch_assoc()) {
                    $records[] = $row;
                }
                
                $response = ["success" => true, "records" => $records];
            } else {
                $response = ["success" => false, "message" => "Invalid session"];
            }
        }
        
        // Get all health records (for admin)
        elseif(isset($_GET['action']) && $_GET['action'] == 'get_all_records') {
            $sql = "SELECT hr.*, u.full_name, u.age, u.gender 
                    FROM health_records hr 
                    JOIN users u ON hr.user_id = u.id 
                    ORDER BY hr.recorded_at DESC";
            $result = $conn->query($sql);
            
            $records = [];
            while($row = $result->fetch_assoc()) {
                $records[] = $row;
            }
            
            $response = ["success" => true, "records" => $records];
        }
        
        // Get real-time latest records (for admin dashboard)
        elseif(isset($_GET['action']) && $_GET['action'] == 'get_realtime_data') {
            $sql = "SELECT u.full_name, hr.* 
                    FROM health_records hr 
                    JOIN users u ON hr.user_id = u.id 
                    WHERE hr.recorded_at >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
                    ORDER BY hr.recorded_at DESC";
            $result = $conn->query($sql);
            
            $realtime = [];
            while($row = $result->fetch_assoc()) {
                $realtime[] = $row;
            }
            
            $response = ["success" => true, "realtime" => $realtime];
        }
        
        break;
        
    case 'DELETE':
        // Delete user
        if(isset($_GET['action']) && $_GET['action'] == 'delete_user') {
            $user_id = $_GET['user_id'];
            
            // First, delete user's health records
            $delete_records = "DELETE FROM health_records WHERE user_id = ?";
            $stmt1 = $conn->prepare($delete_records);
            $stmt1->bind_param("i", $user_id);
            $stmt1->execute();
            
            // Then delete user
            $delete_user = "DELETE FROM users WHERE id = ?";
            $stmt2 = $conn->prepare($delete_user);
            $stmt2->bind_param("i", $user_id);
            
            if($stmt2->execute()) {
                $response = ["success" => true, "message" => "User deleted successfully"];
            } else {
                $response = ["success" => false, "message" => "Failed to delete user"];
            }
        }
        
        // Delete health record
        elseif(isset($_GET['action']) && $_GET['action'] == 'delete_record') {
            $record_id = $_GET['record_id'];
            
            $sql = "DELETE FROM health_records WHERE id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $record_id);
            
            if($stmt->execute()) {
                $response = ["success" => true, "message" => "Record deleted successfully"];
            } else {
                $response = ["success" => false, "message" => "Failed to delete record"];
            }
        }
        
        break;
        
    case 'PUT':
        // Update user profile
        if(isset($_GET['action']) && $_GET['action'] == 'update_profile') {
            $user_id = $input['user_id'];
            $full_name = $input['full_name'];
            $age = $input['age'];
            $gender = $input['gender'];
            $address = $input['address'];
            $contact = $input['contact_number'];
            
            $sql = "UPDATE users SET full_name = ?, age = ?, gender = ?, address = ?, contact_number = ? WHERE id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("sissi", $full_name, $age, $gender, $address, $contact, $user_id);
            
            if($stmt->execute()) {
                $response = ["success" => true, "message" => "Profile updated successfully"];
            } else {
                $response = ["success" => false, "message" => "Failed to update profile"];
            }
        }
        
        break;
        
    default:
        $response = ["success" => false, "message" => "Invalid request method"];
        break;
}

echo json_encode($response);
$conn->close();
?>