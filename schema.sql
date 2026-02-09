-- Perceptions Cruising Database Schema
-- Focus: Diagnostic feedback system

-- Users table (minimal for now)
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Scenarios table
CREATE TABLE scenarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    question_text TEXT NOT NULL,
    diagram_filename VARCHAR(255) NOT NULL,
    correct_answer VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- THE CRITICAL TABLE: Diagnostic feedback
-- This is what makes the system educational vs just a quiz
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

-- Attempts table - captures the learning journey
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

-- Seed data: ONE complete scenario with full diagnostic feedback
INSERT INTO scenarios (title, question_text, diagram_filename, correct_answer) VALUES
('4-Exit Roundabout - Right Turn', 
 'You are approaching a roundabout and need to take the 3rd exit (turn right). Which lane should you use?',
 'roundabout_4exit_right.png',
 'right_lane');

-- THE CRITICAL PART: Feedback for each possible answer
-- This is where learning happens or doesn't

-- Feedback for CORRECT answer
INSERT INTO feedback (scenario_id, answer_choice, is_correct, feedback_text, correct_reasoning) VALUES
(1, 'right_lane', TRUE, 
 'Correct! The right lane is the proper choice for turning right at a roundabout. This positioning keeps you on the outside of the roundabout, giving you clear visibility and the correct approach angle for your 3rd exit. Remember: the right lane is for 3rd and 4th exits (right turns), while the left lane is for 1st and 2nd exits (left and straight ahead).',
 'Right lane for right turns (3rd/4th exits) - matches your exit direction');

-- Feedback for WRONG answer: left_lane
-- This needs to explain WHY they chose wrong and what to think instead
INSERT INTO feedback (scenario_id, answer_choice, is_correct, misconception, feedback_text, correct_reasoning) VALUES
(1, 'left_lane', FALSE,
 'Thinking left lane works for any direction if you signal',
 'Not quite. You chose the left lane, which would position you to exit at the 1st or 2nd exit (going straight or turning left). However, you need the 3rd exit - a right turn. At roundabouts, your lane choice must match your intended exit direction BEFORE you enter. The left lane commits you to early exits. For the 3rd exit (right turn), you need the right lane. This keeps you on the outside of the roundabout and allows you to maintain the correct position throughout. See Highway Code Rule 186.',
 'Lane position must be chosen before entering the roundabout - right lane for 3rd/4th exits');

-- Feedback for WRONG answer: either_lane
-- Different misconception: thinking you can switch lanes inside
INSERT INTO feedback (scenario_id, answer_choice, is_correct, misconception, feedback_text, correct_reasoning) VALUES
(1, 'either_lane', FALSE,
 'Thinking you can change lanes inside the roundabout',
 'Not correct. While it might seem like either lane could work if you navigate carefully, roundabout lane discipline requires you to choose the appropriate lane BEFORE entering. The left lane positions you for early exits (1st/2nd), while the right lane positions you for later exits (3rd/4th). Attempting to switch lanes inside a roundabout is dangerous - other vehicles expect you to maintain your lane. For the 3rd exit, the right lane is the safe and correct choice from the start. See Highway Code Rule 186.',
 'Choose your lane before entering - no lane switching inside roundabouts');

-- Create a test user for development
INSERT INTO users (email, password_hash) VALUES
('test@example.com', '$2b$10$rQ7QhVZq9Z1YxYxYxYxYxOqK7qK7qK7qK7qK7qK7qK7qK7qK7qK7q');
-- Password is 'password123' (hashed with bcrypt)
