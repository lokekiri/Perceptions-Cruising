-- Perceptive Cruising Database Schema
-- Complete schema with driving scenarios and smtm questions

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

CREATE TABLE scenarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    question_text TEXT NOT NULL,
    diagram_filename VARCHAR(255) NOT NULL,
    correct_answer VARCHAR(50) NOT NULL,
    module_type ENUM('roundabouts', 'lane_discipline', 'observations') DEFAULT 'roundabouts',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE feedback (
    id INT AUTO_INCREMENT PRIMARY KEY,
    scenario_id INT NOT NULL,
    answer_choice VARCHAR(50) NOT NULL,
    is_correct BOOLEAN NOT NULL,
    misconception VARCHAR(255),
    feedback_text TEXT NOT NULL,
    correct_reasoning TEXT,
    FOREIGN KEY (scenario_id) REFERENCES scenarios(id),
    UNIQUE KEY unique_scenario_answer (scenario_id, answer_choice)
);

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

CREATE TABLE smtm_questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    question_type ENUM('tell_me', 'show_me') NOT NULL,
    question_text TEXT NOT NULL,
    answer_text TEXT NOT NULL,
    image_filename VARCHAR(255),
    category VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE smtm_attempts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    question_id INT NOT NULL,
    user_answer TEXT,
    is_correct BOOLEAN NOT NULL,
    attempted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (question_id) REFERENCES smtm_questions(id),
    INDEX idx_user_question (user_id, question_id, attempted_at)
);

-- ============================================
-- SEED DATA: ALL 6 SCENARIOS
-- ============================================

-- SCENARIO 1: Roundabout
INSERT INTO scenarios (id, title, question_text, diagram_filename, correct_answer, module_type) VALUES
(1, '4-Exit Roundabout - Right Turn', 
 'You are approaching a roundabout and need to take the 3rd exit (turn right). Which lane should you use?',
 'roundabout_4exit_right.png',
 'right_lane',
 'roundabouts');

INSERT INTO feedback (scenario_id, answer_choice, is_correct, feedback_text, correct_reasoning) VALUES
(1, 'right_lane', TRUE, 
 'Correct! The right lane is the proper choice for turning right at a roundabout. This positioning keeps you on the outside of the roundabout, giving you clear visibility and the correct approach angle for your 3rd exit. Remember: the right lane is for 3rd and 4th exits (right turns), while the left lane is for 1st and 2nd exits (left and straight ahead).',
 'Right lane for right turns (3rd/4th exits) - matches your exit direction');

INSERT INTO feedback (scenario_id, answer_choice, is_correct, misconception, feedback_text, correct_reasoning) VALUES
(1, 'left_lane', FALSE,
 'Thinking left lane works for any direction if you signal',
 'Not quite. You chose the left lane, which would position you to exit at the 1st or 2nd exit (going straight or turning left). However, you need the 3rd exit - a right turn. At roundabouts, your lane choice must match your intended exit direction BEFORE you enter. The left lane commits you to early exits. For the 3rd exit (right turn), you need the right lane. This keeps you on the outside of the roundabout and allows you to maintain the correct position throughout. See Highway Code Rule 186.',
 'Lane position must be chosen before entering the roundabout - right lane for 3rd/4th exits');

INSERT INTO feedback (scenario_id, answer_choice, is_correct, misconception, feedback_text, correct_reasoning) VALUES
(1, 'either_lane', FALSE,
 'Thinking you can change lanes inside the roundabout',
 'Not correct. While it might seem like either lane could work if you navigate carefully, roundabout lane discipline requires you to choose the appropriate lane BEFORE entering. The left lane positions you for early exits (1st/2nd), while the right lane positions you for later exits (3rd/4th). Attempting to switch lanes inside a roundabout is dangerous - other vehicles expect you to maintain your lane. For the 3rd exit, the right lane is the safe and correct choice from the start. See Highway Code Rule 186.',
 'Choose your lane before entering - no lane switching inside roundabouts');

-- SCENARIO 2: Junction
INSERT INTO scenarios (id, title, question_text, diagram_filename, correct_answer, module_type) VALUES
(2, 'T-Junction - Emerging from Side Road',
 'You are stopped at a T-junction wanting to turn right onto a busy main road. Your view is partially restricted by parked cars. What should you do?',
 'junction_restricted_view.png',
 'edge_forward',
 'observations');

INSERT INTO feedback (scenario_id, answer_choice, is_correct, feedback_text, correct_reasoning) VALUES
(2, 'edge_forward', TRUE,
 'Correct! When your view is restricted at a junction, you should edge forward slowly until you can see clearly in both directions. This is the safest way to gain the visibility you need to make an informed decision. Stop again if necessary before committing to emerge. See Highway Code Rule 170.',
 'Edge forward carefully to improve visibility when view is restricted');

INSERT INTO feedback (scenario_id, answer_choice, is_correct, misconception, feedback_text, correct_reasoning) VALUES
(2, 'emerge_slowly', FALSE,
 'Thinking slow speed makes up for poor visibility',
 'Not quite. While emerging slowly sounds cautious, you should not move into the main road until you can actually see if it is safe. The correct approach is to edge forward at the junction line until your view improves, then stop to assess. Only emerge once you have clear visibility and it is genuinely safe. Emerging slowly without proper visibility puts you at risk of collision.',
 'Improve your view first by edging forward, then decide whether to emerge');

INSERT INTO feedback (scenario_id, answer_choice, is_correct, misconception, feedback_text, correct_reasoning) VALUES
(2, 'wait_clear', FALSE,
 'Thinking you must wait until the road is completely empty',
 'Not quite right. While caution is important, waiting for the road to be completely clear might mean you never move - especially on busy roads. The correct technique is to edge forward slowly until you can see properly, then make a judgement about a safe gap. You need sufficient visibility to assess gaps, not necessarily an empty road.',
 'Edge forward to improve visibility, then judge safe gaps - not wait for empty road');

-- SCENARIO 3: Narrow Road
INSERT INTO scenarios (id, title, question_text, diagram_filename, correct_answer, module_type) VALUES
(3, 'Narrow Road with Parked Cars',
 'You are driving along a narrow road. There are parked cars on both sides, and you see a vehicle approaching from the opposite direction. The gap is too narrow for both vehicles. What should you do?',
 'narrow_road_obstruction.png',
 'stop_wait',
 'lane_discipline');

INSERT INTO feedback (scenario_id, answer_choice, is_correct, feedback_text, correct_reasoning) VALUES
(3, 'stop_wait', TRUE,
 'Correct! When the road is too narrow for two vehicles to pass, you should stop and wait for the oncoming vehicle to pass, especially if the obstruction is on your side of the road. The general principle is that priority goes to whoever does not have the obstruction on their side. Be patient and give way safely. See Highway Code Rule 155.',
 'Stop and give way when obstruction is on your side of the road');

INSERT INTO feedback (scenario_id, answer_choice, is_correct, misconception, feedback_text, correct_reasoning) VALUES
(3, 'proceed_carefully', FALSE,
 'Thinking you can squeeze through if careful',
 'Not safe. While proceeding carefully sounds reasonable, if the gap is too narrow for both vehicles, attempting to continue creates a dangerous situation. You risk either collision or forcing the other driver into an unsafe position. The correct action is to stop and give way, allowing the oncoming vehicle to pass first. Courtesy and safety must come before trying to push through tight gaps.',
 'Stop and wait - do not attempt to squeeze through insufficient gaps');

INSERT INTO feedback (scenario_id, answer_choice, is_correct, misconception, feedback_text, correct_reasoning) VALUES
(3, 'sound_horn', FALSE,
 'Thinking horn gives you right of way',
 'Incorrect. Sounding your horn does not give you priority and is inappropriate in this situation. The horn should only be used to warn other road users of your presence when necessary for safety - not to claim right of way. The correct action is to stop and give way to the oncoming vehicle, especially if the obstruction is on your side. See Highway Code Rule 112.',
 'Horn is for warning, not claiming priority - stop and give way instead');

-- SCENARIO 4: Pedestrian Crossing
INSERT INTO scenarios (id, title, question_text, diagram_filename, correct_answer, module_type) VALUES
(4, 'Zebra Crossing - Pedestrian Waiting',
 'You are approaching a zebra crossing. A pedestrian is standing at the kerb looking like they want to cross. What should you do?',
 'pedestrian_zebra_crossing.png',
 'slow_ready',
 'observations');

INSERT INTO feedback (scenario_id, answer_choice, is_correct, feedback_text, correct_reasoning) VALUES
(4, 'slow_ready', TRUE,
 'Correct! When approaching a zebra crossing with a pedestrian waiting at the kerb, you should slow down and be prepared to stop. This gives the pedestrian time to step onto the crossing, at which point you must stop. You should also watch for their body language - if they look like they want to cross, you must be ready to stop. See Highway Code Rule 195.',
 'Slow down and be ready to stop when pedestrians are waiting at crossings');

INSERT INTO feedback (scenario_id, answer_choice, is_correct, misconception, feedback_text, correct_reasoning) VALUES
(4, 'maintain_speed', FALSE,
 'Thinking you only stop if pedestrian is already on the crossing',
 'Not correct. While legally pedestrians have absolute priority once they are on the crossing, best practice is to slow down and be ready to stop when you see someone waiting at the kerb. This anticipation is crucial for safety. By the time they step out, you should already be slowing or stopped. Maintaining speed until they are on the crossing creates a dangerous situation and poor driving practice.',
 'Anticipate pedestrians waiting to cross - slow down before they step out');

INSERT INTO feedback (scenario_id, answer_choice, is_correct, misconception, feedback_text, correct_reasoning) VALUES
(4, 'stop_always', FALSE,
 'Thinking you must always stop at every crossing',
 'Not quite. While pedestrians have priority on zebra crossings, you do not need to stop if there is clearly no one waiting or intending to cross. The correct approach is to slow down and be ready to stop when you see someone at the kerb, then assess their intentions. Stopping unnecessarily when no one is crossing can confuse other road users and is not required.',
 'Be ready to stop when pedestrians are waiting, but assess the situation');

-- SCENARIO 5: Parked Car Obstruction
INSERT INTO scenarios (id, title, question_text, diagram_filename, correct_answer, module_type) VALUES
(5, 'Passing Parked Vehicles',
 'You are driving along and there is a parked car ahead on your side of the road. You need to move out into the oncoming lane to pass it. What should you do?',
 'parked_car_obstruction.png',
 'check_proceed',
 'lane_discipline');

INSERT INTO feedback (scenario_id, answer_choice, is_correct, feedback_text, correct_reasoning) VALUES
(5, 'check_proceed', TRUE,
 'Correct! Before pulling out to pass a parked vehicle, you must check your mirrors, signal your intention, and only proceed when it is safe to do so - meaning no oncoming traffic. If you cannot see far enough ahead or there is oncoming traffic, you must slow down and wait. Always give parked cars plenty of room in case doors open or pedestrians step out. See Highway Code Rule 163.',
 'Check mirrors, signal, wait for safe gap, then proceed with caution');

INSERT INTO feedback (scenario_id, answer_choice, is_correct, misconception, feedback_text, correct_reasoning) VALUES
(5, 'wait_clear', FALSE,
 'Thinking you must wait until the road is completely empty',
 'Not quite. While you need a safe gap to pull out, you do not need to wait for the entire road to be empty. The correct action is to check your mirrors and signal, then proceed when you have a sufficient gap in oncoming traffic. Judge the gap based on your speed and the distance to the obstruction. Waiting unnecessarily for a completely clear road is over-cautious and can hold up traffic behind you.',
 'Judge safe gaps in traffic - not wait for completely empty road');

INSERT INTO feedback (scenario_id, answer_choice, is_correct, misconception, feedback_text, correct_reasoning) VALUES
(5, 'proceed_quickly', FALSE,
 'Thinking speed minimizes risk when passing obstructions',
 'Incorrect. While you should not dawdle unnecessarily, proceeding quickly past parked cars increases risk rather than reducing it. You need to leave plenty of room for doors opening, people stepping out, or children running between cars. The correct approach is to check mirrors and signal, wait for a safe gap, then proceed at a speed that allows you to react to unexpected hazards. Speed does not equal safety here.',
 'Proceed at safe, controlled speed with adequate clearance - not quickly');

-- SCENARIO 6: Mirror Checks
INSERT INTO scenarios (id, title, question_text, diagram_filename, correct_answer, module_type) VALUES
(6, 'Mirror Checks - Changing Direction',
 'You are planning to turn right at the next junction. When should you check your mirrors?',
 'mirror_check_timing.png',
 'before_signal',
 'observations');

INSERT INTO feedback (scenario_id, answer_choice, is_correct, feedback_text, correct_reasoning) VALUES
(6, 'before_signal', TRUE,
 'Correct! You should check your mirrors BEFORE signalling your intention to turn. This is the correct sequence: Mirror - Signal - Manoeuvre (MSM). Checking mirrors first allows you to assess what is behind and alongside you before you signal, ensuring it is safe to make the manoeuvre. Then you signal to inform others of your intention. See Highway Code Rule 161.',
 'Mirror-Signal-Manoeuvre: Check mirrors BEFORE signalling');

INSERT INTO feedback (scenario_id, answer_choice, is_correct, misconception, feedback_text, correct_reasoning) VALUES
(6, 'after_signal', FALSE,
 'Thinking you signal first, then check if it is safe',
 'Not correct. Checking mirrors after signalling reverses the proper sequence. The correct order is Mirror - Signal - Manoeuvre (MSM). You need to know what is behind and beside you BEFORE you signal your intention. This allows you to assess whether the manoeuvre is safe to begin with. Signalling first without checking means you might be indicating a manoeuvre that is not safe to complete.',
 'Check mirrors first to assess safety, then signal your intention');

INSERT INTO feedback (scenario_id, answer_choice, is_correct, misconception, feedback_text, correct_reasoning) VALUES
(6, 'while_turning', FALSE,
 'Thinking mirror checks happen during the manoeuvre',
 'Incorrect. While you should check mirrors throughout your drive, the critical mirror check for a turn must happen BEFORE you signal. The sequence is Mirror - Signal - Manoeuvre. Checking mirrors only while turning is too late - you should have already assessed what is behind you, signalled your intention, and checked again before starting to turn. Mirror checks while turning are supplementary, not the primary check.',
 'Primary mirror check comes before signalling - not during the turn');

-- ============================================
-- SEED DATA: TELL ME QUESTIONS
-- ============================================

INSERT INTO smtm_questions (question_type, question_text, answer_text, category) VALUES
('tell_me', 
 'Tell me how you''d check the brakes are working before starting a journey.', 
 'Brakes should not feel spongy or slack. Test them as you set off — the car should not pull to one side.', 
 'safety_checks'),

('tell_me', 
 'Tell me where you''d find information about the recommended tyre pressures for this car.', 
 'In the manufacturer''s manual. There''s usually a sticker on the door sill or inside the fuel cap.', 
 'tyres'),

('tell_me', 
 'Tell me how you''d check the tyres are safe and legal.', 
 'Check they''re free of cuts and bulges. The tread depth must be at least 1.6mm across the central three-quarters, around the whole circumference. Check pressures with a gauge.', 
 'tyres'),

('tell_me', 
 'Tell me how you''d check the headlights and tail lights are working.', 
 'Turn on the ignition, switch on the headlights, and walk around the car to check. You could also use reflections in a window or garage door.', 
 'lights'),

('tell_me', 
 'Tell me how you''d know if there was a problem with the anti-lock braking system (ABS).', 
 'The ABS warning light on the dashboard should come on when you start the engine and then go off. If it stays on, there''s a fault.', 
 'safety_checks'),

('tell_me', 
 'Tell me how you''d check the direction indicators are working.', 
 'Turn on the ignition, apply the indicators (left and right), and walk around to check. Use the hazard warning lights to check all at once.', 
 'lights'),

('tell_me', 
 'Tell me how you''d check the brake lights are working.', 
 'Turn on the ignition, press the brake pedal, and use a reflection (window, wall, or ask someone to look).', 
 'lights');

-- ============================================
-- SEED DATA: SHOW ME QUESTIONS
-- ============================================

INSERT INTO smtm_questions (question_type, question_text, answer_text, image_filename, category) VALUES
('show_me', 
 'Show me how you''d wash and clean the front windscreen.', 
 'Operate the windscreen washers and wipers.', 
 'windscreen_washer.jpg', 
 'windscreen'),

('show_me', 
 'Show me how you''d wash and clean the rear windscreen.', 
 'Operate the rear windscreen washer and wiper.', 
 'rear_washer.jpg', 
 'windscreen'),

('show_me', 
 'Show me how you''d switch on your dipped headlights.', 
 'Operate the headlight switch to the dipped position.', 
 'headlight_switch.jpg', 
 'lights'),

('show_me', 
 'Show me how you''d set the rear demister.', 
 'Press the heated rear windscreen button.', 
 'demister_button.jpg', 
 'windscreen'),

('show_me', 
 'Show me how you''d operate the horn.', 
 'Press the horn (but only demonstrate when stationary to avoid startling other road users).', 
 'horn.jpg', 
 'controls'),

('show_me', 
 'Show me how you''d demist the front windscreen.', 
 'Set the blowers to windscreen, turn up the heat, use the air con if available.', 
 'demist_controls.jpg', 
 'windscreen'),

('show_me', 
 'Show me how you''d open and close a side window.', 
 'Operate the electric or manual window control.', 
 'window_control.jpg', 
 'controls');

-- ============================================
-- TEST USER
-- ============================================

INSERT INTO users (email, password_hash) VALUES
('test@example.com', '$2b$10$rQ7QhVZq9Z1YxYxYxYxYxOqK7qK7qK7qK7qK7qK7qK7qK7qK7qK7q');
