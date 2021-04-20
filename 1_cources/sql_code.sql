CREATE TABLE cources(
    cource_no VARCHAR(30) PRIMARY KEY,
    title TEXT NOT NULL,
    credits INTEGER
);

CREATE TABLE students(
    stud_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    start_year INTEGER NOT NULL
);

CREATE TABLE exams(
    stud_id INTEGER REFERENCES students(stud_id),
    cource_no VARCHAR(30) REFERENCES cources(cource_no),
    exam_date DATE NULL,
    grade INTEGER NOT NULL,

    -- Будет использоваться составной первичный ключ
    PRIMARY KEY (stud_id, cource_no, exam_date)
);

INSERT INTO cources (cource_no, title, credits)
    VALUES ('CS301', 'Базы данных', 5),
           ('CS305', 'Анализ данных', 10);

INSERT INTO students (stud_id, name, start_year)
    VALUES (1451, 'Анна', 2014),
           (1432, 'Виктор', 2014),
           (1556, 'Нина', 2015);

INSERT INTO exams (stud_id, cource_no, exam_date, grade)
    VALUES (1451, 'CS301', '2016-05-25', 5),
           (1556, 'CS301', '2017-05-23', 5),
           (1451, 'CS305', '2016-05-25', 5),
           (1432, 'CS305', '2016-05-25', 4);

SELECT * FROM students;

-- На самом деле строка выше выглядит именно так, просто ALL опускается
SELECT ALL * FROM students;

-- DISTINCT позволяет выдергивать лишь уникальные значения
-- Но нужно использовать его без фанатизма, так как он снижает производительность
SELECT DISTINCT students.start_year FROM students;

-- Мы можем дергать данные из сразу нескольких таблиц
SELECT * 
    FROM cources, students, exams
    WHERE grade = 5
    ORDER BY name;

-- Так же мы можем джойнить данные при выборке сразу из нескольких таблиц
SELECT * 
    FROM cources, exams
    WHERE cources.cource_no = exams.cource_no;

-- Можно селектить значения из нескольких таблиц с помощью join
SELECT students.name, exams.grade, exams.cource_no
    FROM students
    JOIN exams ON exams.stud_id = students.stud_id 
    WHERE grade = 5
    ORDER BY name;

-- Можно выдернуть имя и курс студента для конкретного курса
-- при этом используя левую часть круга
-- Условие по ограничению курса специально идут в условиях Join,
-- таким образом фильтрация происходит на раннем этапе,
-- Если делать фильтрацию через WHERE, тогда будет фильтроватьс уже результат JOIN
SELECT students.name, exams.grade
    FROM students
    LEFT OUTER JOIN exams ON students.stud_id = exams.stud_id AND exams.cource_no = 'CS301';

-- Можно выдернуть имя и курс студента для конкретного курса
-- при этом используя пересечение значений, то есть не будет NULL
SELECT students.name, exams.grade
    FROM students
    INNER JOIN exams ON students.stud_id = exams.stud_id AND exams.cource_no = 'CS301';