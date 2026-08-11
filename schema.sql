-- UniLearn Hub schema (draft)

CREATE SCHEMA unilearn;
SET search_path TO unilearn;

-- no dependencies

CREATE TABLE Departments (
    department_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE Roles (
    role_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_name VARCHAR(30) UNIQUE NOT NULL
);

-- needs Departments / Roles

CREATE TABLE Programs (
    program_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    program_name VARCHAR(50) UNIQUE NOT NULL,
    department_id INTEGER REFERENCES Departments(department_id) NOT NULL
);

CREATE TABLE Staff (
    staff_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    department_id INTEGER REFERENCES Departments(department_id) NOT NULL,
    role_id INTEGER REFERENCES Roles(role_id) NOT NULL
);

-- needs Programs

CREATE TABLE Students (
    student_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    program_id INTEGER REFERENCES Programs(program_id) NOT NULL
);

CREATE TABLE Courses (
    course_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    course_name VARCHAR(50) NOT NULL,
    credits INTEGER NOT NULL,
    program_id INTEGER REFERENCES Programs(program_id) NOT NULL
);

-- needs Courses / Staff

CREATE TABLE Course_Materials (
    material_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    course_id INTEGER REFERENCES Courses(course_id) NOT NULL,
    staff_id INTEGER REFERENCES Staff(staff_id) NOT NULL,
    title VARCHAR(100) NOT NULL,
    upload_date DATE NOT NULL
);

CREATE TABLE Assignments (
    assignment_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    course_id INTEGER REFERENCES Courses(course_id) NOT NULL,
    title VARCHAR(100) NOT NULL,
    due_date DATE NOT NULL,
    max_marks NUMERIC(5,2) NOT NULL CHECK (max_marks > 0)
);

CREATE TABLE Schedule (
    schedule_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    course_id INTEGER REFERENCES Courses(course_id) NOT NULL,
    day_of_week VARCHAR(10) NOT NULL
        CHECK (day_of_week IN ('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    location VARCHAR(50) NOT NULL,
    CHECK (end_time > start_time)
);

-- junction tables (many-to-many)

CREATE TABLE Enrolments (
    enrolment_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id INTEGER REFERENCES Students(student_id) NOT NULL,
    course_id INTEGER REFERENCES Courses(course_id) NOT NULL,
    enrolment_date DATE NOT NULL,
    UNIQUE (student_id, course_id)
);

CREATE TABLE Submissions (
    submission_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    assignment_id INTEGER REFERENCES Assignments(assignment_id) NOT NULL,
    student_id INTEGER REFERENCES Students(student_id) NOT NULL,
    submitted_at TIMESTAMP NOT NULL,
    file_reference VARCHAR(255) NOT NULL,
    UNIQUE (assignment_id, student_id)
);

-- needs Submissions / Staff

CREATE TABLE Grades (
    grade_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    submission_id INTEGER REFERENCES Submissions(submission_id) UNIQUE NOT NULL,
    marks_awarded NUMERIC(5,2) NOT NULL CHECK (marks_awarded >= 0),
    graded_by INTEGER REFERENCES Staff(staff_id) NOT NULL,
    graded_at TIMESTAMP NOT NULL
);

-- needs Students / Schedule

CREATE TABLE Attendance (
    attendance_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id INTEGER REFERENCES Students(student_id) NOT NULL,
    schedule_id INTEGER REFERENCES Schedule(schedule_id) NOT NULL,
    attendance_date DATE NOT NULL,
    status VARCHAR(10) NOT NULL CHECK (status IN ('present','absent','late')),
    UNIQUE (student_id, schedule_id, attendance_date)
);

CREATE TABLE Feedback (
    feedback_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id INTEGER REFERENCES Students(student_id) NOT NULL,
    course_id INTEGER REFERENCES Courses(course_id) NOT NULL,
    comments TEXT NOT NULL,
    submitted_at TIMESTAMP NOT NULL
);

-- recipient/sender: student or staff -- nullable FKs + CHECK, not a type column

CREATE TABLE Notifications (
    notification_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    recipient_student_id INTEGER REFERENCES Students(student_id),
    recipient_staff_id INTEGER REFERENCES Staff(staff_id),
    message TEXT NOT NULL,
    sent_at TIMESTAMP NOT NULL,
    read_status BOOLEAN NOT NULL DEFAULT FALSE,
    CHECK (
        (recipient_student_id IS NOT NULL AND recipient_staff_id IS NULL)
        OR
        (recipient_student_id IS NULL AND recipient_staff_id IS NOT NULL)
    )
);

CREATE TABLE Messages (
    message_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sender_student_id INTEGER REFERENCES Students(student_id),
    sender_staff_id INTEGER REFERENCES Staff(staff_id),
    recipient_student_id INTEGER REFERENCES Students(student_id),
    recipient_staff_id INTEGER REFERENCES Staff(staff_id),
    body TEXT NOT NULL,
    sent_at TIMESTAMP NOT NULL,
    CHECK (
        (sender_student_id IS NOT NULL AND sender_staff_id IS NULL)
        OR
        (sender_student_id IS NULL AND sender_staff_id IS NOT NULL)
    ),
    CHECK (
        (recipient_student_id IS NOT NULL AND recipient_staff_id IS NULL)
        OR
        (recipient_student_id IS NULL AND recipient_staff_id IS NOT NULL)
    )
);

-- VIEWS -- restrict what a role can see without exposing whole tables

CREATE VIEW Student_Grade_View AS
SELECT
    su.student_id,
    a.assignment_id,
    a.title AS assignment_title,
    su.submitted_at,
    g.marks_awarded,
    a.max_marks,
    g.graded_at
FROM Submissions su
JOIN Assignments a ON a.assignment_id = su.assignment_id
LEFT JOIN Grades g ON g.submission_id = su.submission_id;
-- graded_by left out on purpose -- a student doesn't need to see which
-- staff member graded them

CREATE VIEW Course_Roster_View AS
SELECT
    e.course_id,
    s.student_id,
    s.first_name,
    s.last_name,
    e.enrolment_date
FROM Enrolments e
JOIN Students s ON s.student_id = e.student_id;
-- student email left out -- roster doesn't need it

-- ROLES, least privilege -- USAGE needed before table grants work

CREATE ROLE admin_role LOGIN PASSWORD 'placeholder_change_me';
GRANT USAGE ON SCHEMA unilearn TO admin_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA unilearn TO admin_role;

CREATE ROLE lecturer_role LOGIN PASSWORD 'placeholder_change_me';
GRANT USAGE ON SCHEMA unilearn TO lecturer_role;
GRANT SELECT, INSERT, UPDATE ON
    Courses, Course_Materials, Assignments, Submissions,
    Grades, Feedback, Schedule, Attendance
    TO lecturer_role;
GRANT SELECT ON Students, Enrolments, Departments, Programs TO lecturer_role;
GRANT SELECT ON Course_Roster_View TO lecturer_role;

CREATE ROLE student_role LOGIN PASSWORD 'placeholder_change_me';
GRANT USAGE ON SCHEMA unilearn TO student_role;
GRANT SELECT ON Courses, Schedule, Course_Materials, Programs TO student_role;
GRANT SELECT, INSERT ON Feedback TO student_role;
GRANT SELECT ON Submissions, Enrolments, Attendance TO student_role;
GRANT SELECT ON Student_Grade_View TO student_role;
-- Grades table itself is NOT granted -- students see marks only through
-- Student_Grade_View, which hides graded_by
-- no RLS yet -- this grants read on ALL rows, not just the student's own

CREATE ROLE read_only_role LOGIN PASSWORD 'placeholder_change_me';
GRANT USAGE ON SCHEMA unilearn TO read_only_role;
GRANT SELECT ON ALL TABLES IN SCHEMA unilearn TO read_only_role;