-- Tabelle erstellen und fuellen
USE test;

DROP TABLE IF EXISTS pages;
-- Create a pages table like in TYPO3
CREATE TABLE pages (
    uid INT,
    title VARCHAR(50),
    pid INT,
    sorting INT
);

-- Populate table with sample data
INSERT INTO pages (uid, title, pid, sorting)
VALUES
    (3, '1', 0, 8),
    (5, '1.1', 3, 2),
    (15, '1.3.2.1', 12, 9),
    (7, '1.2', 3, 4),
    (4, '1.1.1', 5, 4),
    (22, '1.1.2', 5, 5),
    (6, '1.3.1', 17, 1),
    (17, '1.3', 3, 8),
    (12, '1.3.2', 17, 9),
    (88, '1.1.1.1', 4, 7)
;

SELECT * FROM pages;

/*
+---+-------+---+-------+
|uid|title  |pid|sorting|
+---+-------+---+-------+
|3  |1      |0  |8      |
|5  |1.1    |3  |2      |
|15 |1.3.2.1|12 |9      |
|7  |1.2    |3  |4      |
|4  |1.1.1  |5  |4      |
|22 |1.1.2  |5  |5      |
|6  |1.3.1  |17 |1      |
|17 |1.3    |3  |8      |
|12 |1.3.2  |17 |9      |
|88 |1.1.1.1|4  |7      |
+---+-------+---+-------+
*/

-- Maximum number to be expected for sorting
SET @maxSorting := 9;
-- Maximum nesting level possible
SET @maxLevels := 4;
WITH RECURSIVE pages_recursive AS (
    -- Select root page
    SELECT
        uid,
        title,
        pid,
        sorting,
        -- starting level 1
        1 as level,
        -- numeric sorting
        POW(@maxSorting + 1, @maxLevels - 1) * sorting as numericSorting,
        -- string sorting with cast
        CAST(LPAD(sorting, FLOOR(LOG10(@maxSorting)) + 1, '0') AS char(200)) as stringSorting
    FROM pages
    WHERE pid = 0

    UNION ALL

    -- Add the rest of the tree with recursion
    SELECT
        subSelect.uid,
        subSelect.title,
        subSelect.pid,
        subSelect.sorting,
        -- increment level
        topSelect.level + 1 as level,
        -- add sublevel numeric sorting to parent level sorting
        topSelect.numericSorting + POW(@maxSorting + 1, (@maxLevels - topSelect.level - 1)) * subSelect.sorting as numericSorting,
        -- concat sublevel sorting
        CONCAT(topSelect.stringSorting, '.', LPAD(subSelect.sorting, FLOOR(LOG10(@maxSorting)) + 1, '0')) as stringSorting
    FROM pages subSelect
    INNER JOIN pages_recursive topSelect ON subSelect.pid = topSelect.uid
)
SELECT
    uid,
    title,
    pid,
    sorting,
    level,
    numericSorting,
    stringSorting
FROM pages_recursive
ORDER BY numericSorting;

/*
+---+-------+---+-------+-----+--------------+-------------+
|uid|title  |pid|sorting|level|numericSorting|stringSorting|
+---+-------+---+-------+-----+--------------+-------------+
|3  |1      |0  |8      |1    |8000          |8            |
|5  |1.1    |3  |2      |2    |8200          |8.2          |
|4  |1.1.1  |5  |4      |3    |8240          |8.2.4        |
|88 |1.1.1.1|4  |7      |4    |8247          |8.2.4.7      |
|22 |1.1.2  |5  |5      |3    |8250          |8.2.5        |
|7  |1.2    |3  |4      |2    |8400          |8.4          |
|17 |1.3    |3  |8      |2    |8800          |8.8          |
|6  |1.3.1  |17 |1      |3    |8810          |8.8.1        |
|12 |1.3.2  |17 |9      |3    |8890          |8.8.9        |
|15 |1.3.2.1|12 |9      |4    |8899          |8.8.9.9      |
+---+-------+---+-------+-----+--------------+-------------+
*/
