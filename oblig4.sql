--IN2090, oblig 4

--DEL 1

--OPPGAVE 1 - Oppvarming
SELECT p.firstname, p.lastname, fc.filmcharacter
FROM film AS f
    INNER JOIN filmparticipation AS fp USING (filmid)
    INNER JOIN person AS p USING (personid)
    INNER JOIN filmcharacter AS fc USING (partid)
WHERE f.title = 'Star Wars' AND fp.parttype = 'cast'
;
--Svar: 108 rows.
--Her er noen skuespillere med 2 ganger fordi både A New Hope og Return Of The Jedi har fatt titel Star Wars.



--OPPGAVE 2 - Land
SELECT country, count(*)
FROM filmcountry
GROUP BY country
ORDER BY count(*) DESC
;
--svar: 190



--Oppgave 3 - Spilletider
SELECT country, avg(cast(time AS int))
FROM runningtime
WHERE time ~ '^\d+$' AND country != '' --Her funket det ikke aa skrive NULL. Oppgaven sier hvor country ikke er lik NULL
GROUP BY country HAVING count(time) >= 200
;
--svar: 44



--OPPGAVE 4 - Komplekse mennesker
SELECT title, count(*) AS genres
FROM film 
    INNER JOIN filmgenre USING (filmid)
    INNER JOIN filmitem USING (filmid)
WHERE filmtype = 'C'
GROUP BY filmid, title
ORDER BY count(*) DESC, title
LIMIT 10
;
/*
svar:
                  title                   | genres
------------------------------------------+--------
 Matilda                                  |      9
 Pokémon Heroes                           |      9
 Utopia's Redemption                      |      9
 Chiquititas: Rincón de luz               |      8
 Escaflowne                               |      8
 Gwoemul                                  |      8
 Hallows Point                            |      8
 Hi no tori                               |      8
 Homeward Bound II: Lost in San Francisco |      8
 Metoroporisu                             |      8
(10 rows)
*/



--OPPGAVE 5

--Table with country, genres and number og movies in each genre for each country.
WITH country_genre_count AS (
    SELECT country, genre, count(*)
    FROM filmcountry
        INNER JOIN filmgenre USING (filmid)
    GROUP BY country, genre
    ORDER BY country, count DESC
)

--Table with country and name of most popular genre.
, country_most_pop_genre AS (
SELECT c.country, genre AS most_popular_genre
FROM country_genre_count AS c
    INNER JOIN (

        --Table with country and the number of movies in most popular genre.
        SELECT country, max(count)
        FROM country_genre_count
        GROUP BY country

    ) as m ON c.country = m.country AND m.max = c.count
)

--Table with number of films, avrage filmrating and most popular genre for each country.
--Some countries have films with no rating or no most popular genre.
SELECT country, films, avg_rating, min(most_popular_genre) AS most_popular_genre
FROM (
    SELECT country, count(country) AS films, avg(rank) AS avg_rating
    FROM filmcountry
        LEFT OUTER JOIN filmrating USING (filmid) --Must LEFT JOIN to include films with no rating in film count.
    GROUP BY country
    ORDER BY films DESC
) AS films_and_avgRating
    LEFT JOIN country_most_pop_genre USING (country)  --This LEFT JOIN includes country with no most_popular_genre

GROUP BY country, films, avg_rating --Some countries have more then one most_popular_genre. This reduces it to only one genre.
;
--Svar: 190 rows. Her er det med land med filmer uten rating, men land med 0 filmer er ikke med.



--OPPGAVE 6 - Vennskap
SELECT *

FROM (
    WITH p AS (
        SELECT concat(firstname, ' ', lastname) AS name, filmid
        FROM film
            INNER JOIN filmcountry USING (filmid)
            INNER JOIN filmparticipation USING (filmid)
            INNER JOIN filmitem AS fi USING (filmid)
            INNER JOIN person USING (personid)
        WHERE country = 'Norway' AND fi.filmtype = 'C'
        ORDER BY name
    )

        SELECT p1.name, p2.name, count(*) AS films_together
        FROM p AS p1
            
            INNER JOIN p AS p2 ON p1.filmid = p2.filmid
                AND p1.name != p2.name
                AND p1.name < p2.name --This takes away duplicate pairs, because p is ordered by name alfabetically.
        GROUP BY p1.name, p2.name
) AS actors_in_same_films
WHERE films_together >= 40
ORDER BY films_together DESC
;
--Svar:
/*
      name       |      name      | films_together
-----------------+----------------+----------------
 Petter Vennerød | Svend Wam      |             47
 Knut Bohwim     | Per A. Anonsen |             42
(2 rows)
*/


--DEL 2

--OPPGAVE 7 - Mot
--Without DISTINCT here there will be some film duplicates beacause a film occurs more than one time in filmgenre if it has more than one genre.
SELECT DISTINCT title, prodyear
FROM film
    LEFT JOIN filmgenre USING (filmid)
    LEFT JOIN filmcountry USING (filmid)
WHERE (title LIKE '%Dark%' OR title LIKE '%Night%')
    AND (genre = 'Horror' OR country = 'Romania')
;
--Svar: 457 rows.


--OPPGAVE 8 - Lunsj
--filmid and number of participants
SELECT title, count(*)
FROM film
    LEFT JOIN filmparticipation USING (filmid)
WHERE prodyear >= 2010
GROUP BY filmid, title HAVING count(*) <= 2
ORDER BY title
;
--Svar: 28 rows.


--OPPGAVE 9 - Introspeksjon
SELECT count(filmid)
FROM film --Because there are movies with no genre also.
WHERE filmid NOT IN(
    SELECT DISTINCT filmid
    FROM filmgenre
    WHERE genre = 'Sci-Fi' OR genre = 'Horror'
)
;
--Svar: 675422 filmer.
/*
Dette kan ikke vaere riktig?
Antall filmer fra den indre sporringen er 18496.
Da skal totalt antall filmer vaere 693918 og det stemmer ikke.
Antall filmer i tabellen film er 692361. Da skal svaret vaere 673865.
*/


--Samme oppgave men med EXCEPT
--Men er det ikke enklere å bruke NOT IN?
SELECT count(filmid)
FROM (
    SELECT filmid FROM film
EXCEPT
    SELECT DISTINCT filmid
    FROM filmgenre
    WHERE genre = 'Sci-Fi' OR genre = 'Horror'
) AS ids
;
--Svar: 675422 filmer. Samme greie her.



--OPPGAVE 10 - Kompetanseheving

--Interresting movies
WITH intFilms AS (
    SELECT filmid, rank, votes
    FROM filmrating
        INNER JOIN filmitem USING (filmid)
    WHERE rank >= 8 AND votes > 1000 AND filmtype = 'C'
    ORDER BY rank DESC, votes DESC
)

--Films with Harrison Ford.
, hf AS (
    SELECT DISTINCT filmid
    FROM intFilms
        INNER JOIN filmparticipation USING (filmid)
        INNER JOIN person USING (personid)
    WHERE firstname = 'Harrison' AND lastname = 'Ford'
)

--Films with genre Comedy or Romance
, cd AS (
    SELECT DISTINCT filmid
    FROM intFilms
        INNER JOIN filmgenre USING (filmid)
    WHERE genre = 'Comedy' OR genre = 'Romance'
)

--Top 10 films
, top10 AS (
    SELECT filmid
    FROM intFilms
    LIMIT 10
)

--Films number of languages. Includes where there are 0 languages.
, num_languages AS (
    SELECT filmid, count(language) AS num_of_languages
    FROM intFilms
        LEFT JOIN filmlanguage USING (filmid)
    GROUP BY filmid
)

--Here we could also use union between the queries instead of naming them.
SELECT title, num_of_languages
FROM hf
    FULL OUTER JOIN cd USING (filmid)
    FUlL OUTER JOIN top10 USING(filmid)
    INNER JOIN num_languages USING (filmid)
    INNER JOIN film USING (filmid)
    ORDER BY title
;
--Svar: 170 rows.
