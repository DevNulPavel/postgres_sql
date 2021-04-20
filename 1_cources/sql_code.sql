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