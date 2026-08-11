-- IM.sql -- resets all UniLearn Hub data between test runs.
-- Structure (tables/views/roles/functions) is untouched -- only rows
-- are cleared, so the business logic script can be re-run repeatedly
-- against a clean state.

SET search_path TO unilearn;

TRUNCATE TABLE
    Departments, Roles, Programs, Staff, Students, Courses,
    Course_Materials, Assignments, Schedule, Enrolments, Submissions,
    Grades, Attendance, Feedback, Notifications, Messages
RESTART IDENTITY CASCADE;
