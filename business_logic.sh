#!/bin/bash
# Creates the business logic functions, seeds demo data, runs each function.
# Usage: ./business_logic.sh [database_name]. Run IM.sql between runs to reset.

set -e

DB_NAME="${1:-unilearn_hub}"
PSQL="psql -d $DB_NAME"

echo "=== Creating functions ==="

$PSQL <<'SQL'
SET search_path TO unilearn;

-- Enrols a student. Already enrolled -> notice + existing id, not an error.
CREATE OR REPLACE FUNCTION fn_enrol_student(p_student_id INT, p_course_id INT)
RETURNS INT AS $$
DECLARE
    v_enrolment_id INT;
BEGIN
    SELECT enrolment_id INTO v_enrolment_id
    FROM Enrolments
    WHERE student_id = p_student_id AND course_id = p_course_id;

    IF v_enrolment_id IS NOT NULL THEN
        RAISE NOTICE 'Student % already enrolled in course % (enrolment_id %)',
            p_student_id, p_course_id, v_enrolment_id;
        RETURN v_enrolment_id;
    END IF;

    INSERT INTO Enrolments (student_id, course_id, enrolment_date)
    VALUES (p_student_id, p_course_id, CURRENT_DATE)
    RETURNING enrolment_id INTO v_enrolment_id;

    RETURN v_enrolment_id;
END;
$$ LANGUAGE plpgsql;

-- Average mark for a course. NULL if nothing graded yet, not 0.
CREATE OR REPLACE FUNCTION fn_course_average(p_course_id INT)
RETURNS NUMERIC AS $$
DECLARE
    v_average NUMERIC;
BEGIN
    SELECT AVG(g.marks_awarded) INTO v_average
    FROM Grades g
    JOIN Submissions su ON su.submission_id = g.submission_id
    JOIN Assignments a ON a.assignment_id = su.assignment_id
    WHERE a.course_id = p_course_id;

    RETURN v_average;
END;
$$ LANGUAGE plpgsql;

-- Records attendance. Duplicate session -> no-op, not an error.
CREATE OR REPLACE FUNCTION fn_record_attendance(
    p_student_id INT, p_schedule_id INT, p_date DATE, p_status VARCHAR
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO Attendance (student_id, schedule_id, attendance_date, status)
    VALUES (p_student_id, p_schedule_id, p_date, p_status)
    ON CONFLICT (student_id, schedule_id, attendance_date) DO NOTHING;
END;
$$ LANGUAGE plpgsql;
SQL

echo "=== Seeding demo data ==="

$PSQL <<'SQL'
SET search_path TO unilearn;

INSERT INTO Departments (department_name) VALUES ('Computer Science');
INSERT INTO Roles (role_name) VALUES ('Lecturer');
INSERT INTO Programs (program_name, department_id) VALUES ('BSc Computing', 1);
INSERT INTO Staff (first_name, last_name, email, department_id, role_id)
    VALUES ('Beverly', 'Crusher', 'bcrusher@test.edu', 1, 1);
INSERT INTO Students (first_name, last_name, email, program_id)
    VALUES ('Jean', 'Picard', 'jpicard@test.edu', 1);
INSERT INTO Courses (course_name, credits, program_id) VALUES ('Databases', 15, 1);
INSERT INTO Schedule (course_id, day_of_week, start_time, end_time, location)
    VALUES (1, 'Monday', '09:00', '11:00', 'Room A1');
INSERT INTO Assignments (course_id, title, due_date, max_marks)
    VALUES (1, 'Assignment 1', '2026-09-01', 50);
SQL

echo "=== fn_enrol_student ==="
$PSQL -c "SET search_path TO unilearn; SELECT fn_enrol_student(1, 1) AS enrolment_id;"
echo "--- calling again: notice, not a duplicate row ---"
$PSQL -c "SET search_path TO unilearn; SELECT fn_enrol_student(1, 1) AS enrolment_id;"

echo "=== fn_course_average, before grading -> NULL ==="
$PSQL -c "SET search_path TO unilearn; SELECT fn_course_average(1) AS average_before_grading;"

$PSQL <<'SQL'
SET search_path TO unilearn;
INSERT INTO Submissions (assignment_id, student_id, submitted_at, file_reference)
    VALUES (1, 1, now(), '/uploads/a1.pdf');
INSERT INTO Grades (submission_id, marks_awarded, graded_by, graded_at)
    VALUES (1, 42, 1, now());
SQL

echo "=== fn_course_average, after grading -> 42.00 ==="
$PSQL -c "SET search_path TO unilearn; SELECT fn_course_average(1) AS average_after_grading;"

echo "=== fn_record_attendance ==="
$PSQL -c "SET search_path TO unilearn; SELECT fn_record_attendance(1, 1, CURRENT_DATE, 'present');"
$PSQL -c "SET search_path TO unilearn; SELECT * FROM Attendance;"
echo "--- recording the same session again: no error, no duplicate ---"
$PSQL -c "SET search_path TO unilearn; SELECT fn_record_attendance(1, 1, CURRENT_DATE, 'present');"
$PSQL -c "SET search_path TO unilearn; SELECT count(*) AS attendance_row_count FROM Attendance;"

echo "=== Done ==="
