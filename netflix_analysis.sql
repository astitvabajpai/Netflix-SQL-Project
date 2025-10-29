CREATE DATABASE netflix;
DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix
(
    show_id      VARCHAR(5),
    type         VARCHAR(10),
    title        VARCHAR(250),
    director     VARCHAR(550),
    casts        VARCHAR(1050),
    country      VARCHAR(550),
    date_added   VARCHAR(55),
    release_year INT,
    rating       VARCHAR(15),
    duration     VARCHAR(15),
    listed_in    VARCHAR(250),
    description  VARCHAR(550)
);

SELECT * FROM netflix;


-- Task1:Count the Number of Movies vs TV Shows
SELECT type,
COUNT(*)
FROM netflix
GROUP BY 1;

-- Task 2:Find the Most Common Rating for Movies and TV Shows
WITH RatingCounts AS (
    SELECT 
        `type`,
        rating,
        COUNT(*) AS rating_count
    FROM netflix
    GROUP BY `type`, rating
),
RankedRatings AS (
    SELECT 
        `type`,
        rating,
        rating_count,
        RANK() OVER (PARTITION BY `type` ORDER BY rating_count DESC) AS rk
    FROM RatingCounts
)
SELECT 
    `type`,
    rating AS most_frequent_rating
FROM RankedRatings
WHERE rk = 1;

-- Task3: List All Movies Released in a Specific Year (e.g., 2020)
SELECT * from netflix
WHERE release_year = 2020;

-- Task4:Find the Top 5 Countries with the Most Content on Netflix
SELECT country, total_content
FROM (
  SELECT jt.country,
         COUNT(*) AS total_content
  FROM netflix
  CROSS JOIN JSON_TABLE(
        CONCAT('["', REPLACE(country, ',', '","'), '"]'),
        '$[*]' COLUMNS (country VARCHAR(100) PATH '$')
      ) AS jt
  WHERE jt.country IS NOT NULL AND jt.country <> ''
  GROUP BY jt.country
) AS t1
ORDER BY total_content DESC
LIMIT 5;


-- TASK5:Find the movie with longest duration
SELECT
  *
FROM
  netflix
WHERE
  type = 'Movie'
ORDER BY
  CAST(
    SUBSTRING_INDEX(duration, ' ', 1)
    AS UNSIGNED
  ) DESC;

-- TASK6:Find Content Added in the Last 5 Years
SELECT *
FROM netflix
WHERE 
  STR_TO_DATE(date_added, '%M %e, %Y') >= CURDATE() - INTERVAL 5 YEAR;

-- TASK7:Find All Movies/TV Shows by Director 'Rajiv Chilaka'
WITH RECURSIVE nums AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM nums WHERE n < 20  -- adjust 20 to maximum expected number of directors
),
split_directors AS (
  SELECT
    n.*,
    TRIM(
      SUBSTRING_INDEX(
        SUBSTRING_INDEX(n.director, ',', nums.n),
        ',', -1
      )
    ) AS director_name
  FROM netflix AS n
  JOIN nums
    ON nums.n <= 1 + (LENGTH(n.director) - LENGTH(REPLACE(n.director, ',', '')))
)
SELECT *
FROM split_directors
WHERE director_name = 'Delhiprasad Deenadayalan';

-- TASK8:List All TV Shows with More Than 5 Seasons
SELECT * 
FROM netflix
WHERE 
type='TV SHOW'
AND CAST(
TRIM(SUBSTRING_INDEX(DURATION,' ',1))
AS UNSIGNED
) > 5;

-- TASK9:Count the Number of Content Items in Each Genre
SELECT 
TRIM(jt.genre) AS genre,
COUNT(*) AS total_content
FROM netflix AS n
JOIN JSON_TABLE(
     CONCAT('["',REPLACE(n.listed_in,',','","'),'"]'),
     '$[*]' COLUMNS (
       genre VARCHAR(255) PATH '$'
     )
   ) AS jt
  ON TRUE
WHERE jt.genre IS NOT NULL AND jt.genre <> ''
GROUP BY TRIM(jt.genre)
ORDER BY total_content DESC;

-- TASK10:Find each year and the average numbers of content release in India on netflix.
SELECT
  country,
  release_year,
  COUNT(show_id) AS total_release,
  ROUND(
    CAST(COUNT(show_id) AS DECIMAL(10,2)) / CAST(t.total_india AS DECIMAL(10,2)) * 100,
    2
  ) AS avg_release
FROM netflix
JOIN (
  SELECT COUNT(show_id) AS total_india
  FROM netflix
  WHERE country = 'India'
) AS t
  ON 1 = 1
WHERE country = 'India'
GROUP BY country, release_year, t.total_india
ORDER BY avg_release DESC
LIMIT 5;


-- Task11. List All Movies that are Documentaries
SELECT * FROM netflix
WHERE
listed_in LIKE '%Documentaries';

-- Task12. Find All Content Without a Director
SELECT *
FROM netflix
WHERE director IS NULL OR director = '';

-- Task13:Find How Many Movies Actor 'Salman Khan' Appeared in the Last 10 Years
SELECT *
FROM netflix
WHERE
  TRIM(casts) LIKE '%Salman Khan%'
  AND release_year > YEAR(CURDATE()) - 10;
;

-- Task14:Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in India
SELECT
  TRIM(jt.actor) AS actor,
  COUNT(*) AS total_appearances
FROM netflix AS n
JOIN JSON_TABLE(
    CONCAT('["', REPLACE(n.casts, ',', '","'), '"]'),
    "$[*]" COLUMNS (actor VARCHAR(255) PATH "$")
) AS jt ON TRUE
WHERE n.country = 'India'
GROUP BY actor
ORDER BY total_appearances DESC
LIMIT 10;

-- TASK15:Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords
SELECT 
    category,
    COUNT(*) AS content_count
FROM (
    SELECT 
        CASE 
            WHEN description LIKE '%kill%' OR description LIKE '%violence%' THEN 'Bad'
            ELSE 'Good'
        END AS category
    FROM netflix
) AS categorized_content
GROUP BY category;
