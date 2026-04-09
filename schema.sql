-- Perceptive Cruising Database Schema
-- Complete schema including diagnostic scenarios and SMTM questions

-- ============================================
-- USERS & AUTHENTICATION
-- ============================================

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- DRIVING SCENARIOS MODULE
-- ============================================

-- Scenarios table (roundabouts, lane discipline, observations)
CREATE TABLE scenarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    question_text TEXT NOT NULL,
    diagram_filename VARCHAR(255) NOT NULL,
    correct_answer VARCHAR(50) NOT NULL,
    module_type ENUM('roundabouts', 'lane_discipline', 'observations') DEFAULT 'roundabouts',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Diagnostic feedback - the core educational mechanism
CREATE TABLE feedback (
    id INT AUTO_INCREMENT PRIMARY KEY,
    scenario_id INT NOT NULL,
    answer_choice VARCHAR(50) NOT NULL,
    is_correct BOOLEAN NOT NULL,
    misconception VARCHAR(255), -- What mental model led to this wrong answer?
    feedback_text TEXT NOT NULL, -- The actual explanation
    correct_reasoning TEXT,      -- What they should think instead
    FOREIGN KEY (scenario_id) REFERENCES scenarios(id),
    UNIQUE KEY unique_scenario_answer (scenario_id, answer_choice)
);

-- Attempts table - captures the learning journey (wrong -> right)
CREATE TABLE attempts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    scenario_id INT NOT NULL,
    selected_answer VARCHAR(50) NOT NULL,
    is_correct BOOLEAN NOT NULL,
    attempted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (scenario_id) REFERENCES scenarios(id),
    INDEX idx_user_scenario (user_id, scenario_id, attempted_at)
);

-- ============================================
-- SHOW ME TELL ME MODULE
-- ============================================

-- SMTM questions table
CREATE TABLE smtm_questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    question_type ENUM('tell_me', 'show_me') NOT NULL,
    question_text TEXT NOT NULL,
    answer_text TEXT NOT NULL,
    image_filename VARCHAR(255), -- For "show me" visual demonstrations
    category VARCHAR(100), -- e.g., 'lights', 'tyres', 'windscreen', 'safety_checks'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- SMTM user attempts (different from scenarios - no diagnostic feedback)
CREATE TABLE smtm_attempts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    question_id INT NOT NULL,
    user_answer TEXT, -- Their typed/selected answer
    is_correct BOOLEAN NOT NULL,
    attempted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (question_id) REFERENCES smtm_questions(id),
    INDEX idx_user_question (user_id, question_id, attempted_at)
);

-- ============================================
-- SEED DATA: SCENARIOS
-- ============================================

INSERT INTO scenarios (title, question_text, diagram_filename, correct_answer, module_type) VALUES
('4-Exit Roundabout - Right Turn', 
 'You are approaching a roundabout and need to take the 3rd exit (turn right). Which lane should you use?',
 'roundabout_4exit_right.png',
 'right_lane',
 'roundabouts');

-- Feedback for CORRECT answer
INSERT INTO feedback (scenario_id, answer_choice, is_correct, feedback_text, correct_reasoning) VALUES
(1, 'right_lane', TRUE, 
 'Correct! The right lane is the proper choice for turning right at a roundabout. This positioning keeps you on the outside of the roundabout, giving you clear visibility and the correct approach angle for your 3rd exit. Remember: the right lane is for 3rd and 4th exits (right turns), while the left lane is for 1st and 2nd exits (left and straight ahead).',
 'Right lane for right turns (3rd/4th exits) - matches your exit direction');

-- Feedback for WRONG answer: left_lane
INSERT INTO feedback (scenario_id, answer_choice, is_correct, misconception, feedback_text, correct_reasoning) VALUES
(1, 'left_lane', FALSE,
 'Thinking left lane works for any direction if you signal',
 'Not quite. You chose the left lane, which would position you to exit at the 1st or 2nd exit (going straight or turning left). However, you need the 3rd exit - a right turn. At roundabouts, your lane choice must match your intended exit direction BEFORE you enter. The left lane commits you to early exits. For the 3rd exit (right turn), you need the right lane. This keeps you on the outside of the roundabout and allows you to maintain the correct position throughout. See Highway Code Rule 186.',
 'Lane position must be chosen before entering the roundabout - right lane for 3rd/4th exits');

-- Feedback for WRONG answer: either_lane
INSERT INTO feedback (scenario_id, answer_choice, is_correct, misconception, feedback_text, correct_reasoning) VALUES
(1, 'either_lane', FALSE,
 'Thinking you can change lanes inside the roundabout',
 'Not correct. While it might seem like either lane could work if you navigate carefully, roundabout lane discipline requires you to choose the appropriate lane BEFORE entering. The left lane positions you for early exits (1st/2nd), while the right lane positions you for later exits (3rd/4th). Attempting to switch lanes inside a roundabout is dangerous - other vehicles expect you to maintain your lane. For the 3rd exit, the right lane is the safe and correct choice from the start. See Highway Code Rule 186.',
 'Choose your lane before entering - no lane switching inside roundabouts');

-- ============================================
-- SEED DATA: TELL ME QUESTIONS
-- ============================================

INSERT INTO smtm_questions (question_type, question_text, answer_text, category) VALUES
('tell_me', 
 'Tell me how you'd check the brakes are working before starting a journey.', 
 'Brakes should not feel spongy or slack. Test them as you set off — the car should not pull to one side.', 
 'safety_checks'),

('tell_me', 
 'Tell me where you'd find information about the recommended tyre pressures for this car.', 
 'In the manufacturer's manual. There's usually a sticker on the door sill or inside the fuel cap.', 
 'tyres'),

('tell_me', 
 'Tell me how you'd check the tyres are safe and legal.', 
 'Check they're free of cuts and bulges. The tread depth must be at least 1.6mm across the central three-quarters, around the whole circumference. Check pressures with a gauge.', 
 'tyres'),

('tell_me', 
 'Tell me how you'd check the headlights and tail lights are working.', 
 'Turn on the ignition, switch on the headlights, and walk around the car to check. You could also use reflections in a window or garage door.', 
 'lights'),

('tell_me', 
 'Tell me how you'd know if there was a problem with the anti-lock braking system (ABS).', 
 'The ABS warning light on the dashboard should come on when you start the engine and then go off. If it stays on, there's a fault.', 
 'safety_checks'),

('tell_me', 
 'Tell me how you'd check the direction indicators are working.', 
 'Turn on the ignition, apply the indicators (left and right), and walk around to check. Use the hazard warning lights to check all at once.', 
 'lights'),

('tell_me', 
 'Tell me how you'd check the brake lights are working.', 
 'Turn on the ignition, press the brake pedal, and use a reflection (window, wall, or ask someone to look).', 
 'lights');

-- ============================================
-- SEED DATA: SHOW ME QUESTIONS
-- ============================================

INSERT INTO smtm_questions (question_type, question_text, answer_text, image_filename, category) VALUES
('show_me', 
 'Show me how you'd wash and clean the front windscreen.', 
 'Operate the windscreen washers and wipers.', 
 'windscreen_washer.jpg', 
 'windscreen'),

('show_me', 
 'Show me how you'd wash and clean the rear windscreen.', 
 'Operate the rear windscreen washer and wiper.', 
 'rear_washer.jpg', 
 'windscreen'),

('show_me', 
 'Show me how you'd switch on your dipped headlights.', 
 'Operate the headlight switch to the dipped position.', 
 'headlight_switch.jpg', 
 'lights'),

('show_me', 
 'Show me how you'd set the rear demister.', 
 'Press the heated rear windscreen button.', 
 'demister_button.jpg', 
 'windscreen'),

('show_me', 
 'Show me how you'd operate the horn.', 
 'Press the horn (but only demonstrate when stationary to avoid startling other road users).', 
 'horn.jpg', 
 'controls'),

('show_me', 
 'Show me how you'd demist the front windscreen.', 
 'Set the blowers to windscreen, turn up the heat, use the air con if available.', 
 'demist_controls.jpg', 
 'windscreen'),

('show_me', 
 'Show me how you'd open and close a side window.', 
 'Operate the electric or manual window control.', 
 'window_control.jpg', 
 'controls');

-- ============================================
-- TEST USER
-- ============================================

INSERT INTO users (email, password_hash) VALUES
('test@example.com', '$2b$10$rQ7QhVZq9Z1YxYxYxYxYxOqK7qK7qK7qK7qK7qK7qK7qK7qK7qK7q');
-- Password is 'password123' (hashed with bcrypt)
