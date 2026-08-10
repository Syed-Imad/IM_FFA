

# TABLES

CREATE TABLE Departments (
    department_id INTEGER PRIMARY KEY,
    department_name VARCHAR(20) UNIQUE NOT NULL
);


CREATE TABLE Staff (
    staff_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    department_id INTEGER REFERENCES Departments(department_id)
);


CREATE TABLE Programs (
    program_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    program_name VARCHAR(20) NOT NULL UNIQUE,
    department_id INTEGER REFERENCES Departments(department_id) NOT NULL
);


CREATE TABLE Students (
    student_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    program_id INTEGER REFERENCES Programs(program_id) NOT NULL
);

CREATE TABLE Courses (
    course_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    course_name VARCHAR(50) NOT NULL,
    program_id INTEGER REFERENCES Programs(program_id) NOT NULL
);


# JUCTION TABLES
CREATE TABLE Enrolments (
    UNIQUE (student_id, course_id)
    enrolment_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id INTEGER REFERENCES Students(student_id) NOT NULL,
    course_id INTEGER REFERENCES Courses(course_id) NOT NULL,
    enrolment_date DATE NOT NULL
);