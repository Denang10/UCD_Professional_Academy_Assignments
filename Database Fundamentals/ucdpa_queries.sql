-----------------------------------------Student Table Creation-------------------------------------------------------------------------

CREATE TABLE student
  (
    sid   INT            NOT NULL,
    sname VARCHAR(50)    NOT NULL,
    sex   CHAR(1)        NOT NULL CHECK (sex IN ('m', 'f')), --check allows me to restrict the space used as it only allows what I specify
    age   SMALLINT       NOT NULL,
    year  SMALLINT       NOT NULL,
    gpa   DECIMAL(10, 9) NOT NULL CHECK (gpa >= 0.0 AND gpa <= 4.0),  --restricting possible values for gpa to save space
    PRIMARY KEY (sid)

  )

--indexes will be created to help optimise joins and where statements (PostgreSQL automatically creates an index for primary keys)

-----------------------------------------Dept Table Creation-------------------------------------------------------------------------


CREATE TABLE dept
  (
    dname   CHAR(23) NOT NULL,
    numphds INT      NOT NULL,
    PRIMARY KEY (dname)
  )

-----------------------------------------Prof Table Creation-------------------------------------------------------------------------

CREATE TABLE prof
  (
    pname VARCHAR(20) NOT NULL,
    dname VARCHAR(23) NOT NULL,
    PRIMARY KEY (pname),
    FOREIGN KEY (dname) REFERENCES dept (dname)
  )

-----------------------------------------Course Table Creation-------------------------------------------------------------------------

CREATE TABLE course
  (
    cno   INT         NOT NULL,
    cname VARCHAR(30) NOT NULL,
    dname VARCHAR(23),
    PRIMARY KEY (cno),
    FOREIGN KEY (dname) REFERENCES dept (dname)
  )

CREATE INDEX idx_course_dname ON course (dname) --Index created for dname for optimising join operations

-----------------------------------------Major Table Creation-------------------------------------------------------------------------

CREATE TABLE major
  (
    dname VARCHAR(23) NOT NULL,
    sid   INT         NOT NULL,
    PRIMARY KEY (dname, sid),						--composite primary key
    FOREIGN KEY (dname) REFERENCES dept (dname),		--each of these fields are also individually foreign keys on other tables
    FOREIGN KEY (sid) REFERENCES student (sid)
  )

-----------------------------------------Section Table Creation-------------------------------------------------------------------------

CREATE TABLE section
  (
    dname  VARCHAR(23) NOT NULL,
    cno    INT         NOT NULL,
    sectno SMALLINT    NOT NULL,
    pname  VARCHAR(20) NOT NULL,
    PRIMARY KEY (cno, sectno),
    FOREIGN KEY (dname) REFERENCES dept (dname),
    FOREIGN KEY (cno) REFERENCES course (cno),
    FOREIGN KEY (pname) REFERENCES prof (pname)
  )

--sanitary engineering needed to be updated in file as it had a cno of 561 which contradicted with what was in course where it has 315

CREATE INDEX idx_section_dname ON section (dname)

-----------------------------------------Enroll Table Creation-------------------------------------------------------------------------

CREATE TABLE enroll
  (
    sid    INT           NOT NULL,
    grade  DECIMAL(2, 1) NOT NULL,
    dname  VARCHAR(23)   NOT NULL,
    cno    INT           NOT NULL,
    sectno SMALLINT      NOT NULL,
    PRIMARY KEY (sid, cno, sectno),
    FOREIGN KEY (sid) REFERENCES student (sid),
    FOREIGN KEY (cno, sectno) REFERENCES section (cno, sectno)
  )

--enroll has too many rows, had to take off a few to be in line with other tables

CREATE INDEX idx_enroll_dname ON enroll (dname)

-----------------------------------------Question 1-------------------------------------------------------------------------

SELECT
        pname, numphds	--Included numphds to be able to see answer more easily
FROM
        prof p	
    LEFT JOIN
      dept d			--join in order to get number of phd's from dept
        ON p.dname = d.dname
WHERE
        numphds < 50

-----------------------------------------Question 2-------------------------------------------------------------------------

SELECT
        sname, gpa
FROM
        student	--names of students printed
ORDER BY
        gpa ASC
limit
  10					--Question doesn't specify number of students required so ten was selected

-----------------------------------------Question 3-------------------------------------------------------------------------

SELECT
        c.cname,
        c.cno,
        s.sectno,
        AVG(gpa)
FROM
        course c		--even though question didn't specify, included cname...
    LEFT JOIN
      section s											--...to specify the various classes, otherwise course...
        ON c.cno = s.cno											--...wouldn't be necessary in this query, only sector
    LEFT JOIN
      enroll e
        ON s.cno = e.cno
          AND s.sectno = e.sectno					--enroll was required to help us join to student using sid
    LEFT JOIN
      student st
        ON e.sid = st.sid
WHERE
        c.dname = 'Computer Sciences'
GROUP BY
        1,
        2,
        3

-----------------------------------------Question 4-------------------------------------------------------------------------

SELECT
        c.cname,
        s.sectno,
        COUNT(st.sid) as No_Of_Students
FROM
        course c	--assuming sector name is cname
    LEFT JOIN
      section s
        ON c.cno = s.cno
    LEFT JOIN
      enroll e
        ON s.cno = e.cno
          AND s.sectno = e.sectno				--similar join to prevoius question
    LEFT JOIN
      student st
        ON e.sid = st.sid
GROUP BY
        1,
        2
HAVING
        COUNT(st.sid) > 6								--having used instead of where for aggregated fields

-----------------------------------------Question 5-------------------------------------------------------------------------

SELECT
        d.dname,
        COUNT(c.cname) as No_of_Classes
FROM
        dept d
    LEFT JOIN
      course c
        ON d.dname = c.dname
GROUP BY
        1								--not mentioned before but numbers (index) can be used instead of field names

-----------------------------------------Question 6-------------------------------------------------------------------------

SELECT
        dname,
        age
FROM
        major m		--listing dname as question instructs, age for convenience
    LEFT JOIN
      student s
        ON m.sid = s.sid
WHERE
        age < 18

-----------------------------------------Question 7-------------------------------------------------------------------------

SELECT
        sname,
        m.dname AS major
FROM
        course c	--dname form major table gives the major, dname from other tables...
    LEFT JOIN
      enroll e								--gives department pertaining to their course so must specify major dname
        ON c.cno = e.cno
    LEFT JOIN
      student st
        ON e.sid = st.sid
    LEFT JOIN
      major m
        ON m.sid = st.sid
WHERE
        cname LIKE '%Geometry%'

-----------------------------------------Question 8-------------------------------------------------------------------------

SELECT DISTINCT
        m.dname,
        numphds
FROM
        major m	--used distinct to only give me unique values for department name
    LEFT JOIN
      dept d
        ON m.dname = d.dname
WHERE
        m.dname NOT IN (SELECT
                    m.dname AS major
            FROM
                    course c			--created subquery of last question to single out departments...
                LEFT JOIN
                  enroll e								--...that don't have majors doing geometry
                      ON c.cno = e.cno
                LEFT JOIN
                  student st
                      ON e.sid = st.sid
                LEFT JOIN
                  major m
                      ON m.sid = st.sid
            WHERE
                    cname LIKE '%Geometry%')

-----------------------------------------Question 9-------------------------------------------------------------------------

SELECT
        sname
FROM
        enroll e
    LEFT JOIN
      student st
        ON e.sid = st.sid
WHERE
        e.dname IN ('Computer Sciences', 'Mathematics')

-----------------------------------------Question 10-------------------------------------------------------------------------


SELECT
        MAX(age) - MIN(age) AS Largest_Age_Difference
FROM
        major m		--encircle the field around the functions to achieve
    LEFT JOIN
      student st												--min and max ages
        ON m.sid = st.sid
WHERE
        dname = 'Computer Sciences'

-----------------------------------------Question 11-------------------------------------------------------------------------

SELECT
        dname,
        AVG(gpa)
FROM
        major m
    LEFT JOIN
      student st
        ON m.sid = st.sid
WHERE
        gpa < 1.0
GROUP BY
        1

-----------------------------------------Question 12-------------------------------------------------------------------------

Explain Analyze SELECT
        st.sid,
        sname,
        gpa,
        COUNT(e.dname) AS No_Of_Courses
FROM
        student st	--summed up dname so that it gives the number of courses...
    LEFT JOIN
      enroll e											--...from each department each student attends
        ON st.sid = e.sid
    LEFT JOIN
      course c
        ON e.dname = c.dname
WHERE
        e.dname = 'Civil Engineering'							--Concentrated on Civil Engineering
GROUP BY
        1,
        2,
        3
HAVING
        COUNT(e.dname) = 3									--3 courses in Civil Engineering so student with a 3 do all of them

