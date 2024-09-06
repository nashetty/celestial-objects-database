-- please note that these queries examples have been optimised for MySQL Workbench
USE space;

SHOW TABLES;
DESCRIBE constellations;
DESCRIBE galaxies;
DESCRIBE instrumentation;
DESCRIBE moons;
DESCRIBE observability;
DESCRIBE planets;
DESCRIBE stars;

-- demonstration of how the trigger works
-- insert data to planets and galaxies table, for demonstration purposes
INSERT INTO planets(id, planet_id, planet_name)
VALUES (15, 'P15', 'Demonstration');
SELECT * FROM planets;

INSERT INTO galaxies(id, galaxy_id, galaxy_name)
VALUES (38, 'G38', 'Demonstration');
SELECT * FROM galaxies;

-- insert data to observability table for demonstration purposes
CALL InsertObservabilityObject (1, 'P15', 'planet');
CALL InsertObservabilityObject (1, 'G38', 'galaxy');
SELECT * FROM observability;

-- delete data from planets and galaxies
SET SQL_SAFE_UPDATES = 0; -- disable safe update mode
DELETE FROM planets WHERE planet_id = 'P15';
SELECT * FROM planets;

DELETE FROM galaxies WHERE galaxy_id = 'G38';
SELECT * FROM galaxies;

SET SQL_SAFE_UPDATES = 1; -- enable safe update mode

-- check if observability table has been updated
SELECT * FROM observability;
SELECT * FROM observability WHERE object_id = 'P15' OR object_id = 'G38';

-- View combining multiple tables
-- Display names of all the stars, constellations and galaxies that are observable from London (latitude 51.5 N)
CREATE OR REPLACE VIEW visible_from_London
AS
	SELECT 
		s.star_id AS 'ID',
        'star' AS 'Object Type',
        s.common_name AS 'Name',
        s.meaning AS 'Meaning'
	FROM stars AS s
	JOIN constellations AS c ON s.constellation_id = c.constellation_id
	WHERE c.constellation_id IN (SELECT c.constellation_id FROM constellations AS c WHERE c.visibility_degrees_North >= 51.5)
    
    UNION ALL
    
    SELECT
		c.constellation_id,
        'constellation',
        c.constellation_name,
        c.english_name
	FROM constellations AS c
    WHERE constellation_id IN (SELECT constellation_id FROM constellations WHERE visibility_degrees_North >= 51.5)
	
    UNION ALL
    
    SELECT
		g.galaxy_id AS 'ID',
        'galaxy',
        g.galaxy_name,
        g.meaning
	FROM galaxies AS g
    JOIN constellations AS c ON c.constellation_id = g.constellation_id
    WHERE c.constellation_id IN (SELECT c.constellation_id FROM constellations WHERE visibility_degrees_North >= 51.5);

SELECT * FROM visible_from_London;

-- Calling the stored function to calculate average radius of
-- all Terrestrial planets
SELECT avg_planet_radius_per_type('Terrestrial') AS 'Average Radius of Terrestrial Planets in km';

-- all Gas giants
SELECT avg_planet_radius_per_type('Gas giant') AS 'Average Radius of Gas giants in km';

-- all Ice giants
SELECT avg_planet_radius_per_type('Ice giant') AS 'Average Radius of Ice giants in km';

-- all Dwarf planets
SELECT avg_planet_radius_per_type('Dwarf Planet') AS 'Average Radius of Dwarf Planets in km';

-- query with a subquery
-- Display the brightest star (or stars if a tie) in each constellation 
-- NB. the lower the apparent_magnitude, the brighter the star
SELECT 
    c.constellation_name AS 'Constellation',
    s.common_name AS 'Brightest Star',
    MIN(s.apparent_magnitude) AS 'Brightness',
    s.meaning AS 'Star Name Meaning' 
FROM stars AS s
JOIN constellations AS c ON c.constellation_id = s.constellation_id
WHERE s.apparent_magnitude = (SELECT MIN(apparent_magnitude) FROM stars WHERE constellation_id = c.constellation_id)
GROUP BY c.constellation_name, s.common_name, s.meaning
ORDER BY c.constellation_name;

-- a view that uses at least 3-4 base tables
-- a view joining observability table & planets, moons, stars, constellations, galaxies, instrumentation
CREATE OR REPLACE VIEW observable_objects
AS
	SELECT
		i.instrument,
		p.planet_name AS Object_Name,
        o.object_type AS Object_Type
	FROM observability AS o
    JOIN planets AS p ON o.object_id = p.planet_id
    JOIN instrumentation AS i ON o.instrument_id = i.instrument_id
        
UNION ALL
	SELECT
		i.instrument,
		m.IAU_name AS Object_Name,
        o.object_type AS Object_Type
	FROM observability AS o
	JOIN moons AS m ON o.object_id = m.moon_id
    JOIN instrumentation AS i ON o.instrument_id = i.instrument_id
    
UNION ALL
	SELECT
		i.instrument,
		s.common_name AS Object_Name,
        o.object_type AS Object_Type
	FROM observability AS o
	JOIN stars AS s ON o.object_id = s.star_id
    JOIN instrumentation AS i ON o.instrument_id = i.instrument_id
    
UNION ALL
	SELECT 
		i.instrument,
		c.constellation_name AS Object_Name,
		o.object_type AS Object_Type
	FROM observability AS o
    JOIN constellations AS c ON o.object_id = c.constellation_id
    JOIN instrumentation AS i ON o.instrument_id = i.instrument_id
    
UNION ALL
	SELECT
		i.instrument,
		g.galaxy_name AS Object_Name,
        o.object_type AS Object_Type
	FROM observability AS o
    JOIN galaxies AS g ON o.object_id = g.galaxy_id
    JOIN instrumentation AS i ON o.instrument_id = i.instrument_id;

-- view all the data from observable_objects	
SELECT * FROM observable_objects;

-- display all objects visible with Naked Eye (with numbers added)
SELECT ROW_NUMBER() OVER() AS 'Visible with Naked Eye ', Object_Name, Object_Type
FROM observable_objects 
WHERE instrument = 'Naked Eye';

-- display all object visible with Amateur Telescope (with numbers added)
SELECT ROW_NUMBER() OVER() AS 'Visible with Amateur Telescope', Object_Name, Object_Type
FROM observable_objects 
WHERE instrument = 'Amateur Telescope';

-- display all objects visible with Observatory Telescope (with numbers added)
SELECT ROW_NUMBER() OVER() AS 'Visible with Observatory Telescope', Object_Name, Object_Type
FROM observable_objects 
WHERE instrument = 'Observatory Telescope';

-- display all objects visible with Space Telescope (with numbers added)
SELECT ROW_NUMBER() OVER() AS 'Visible with Space Telescope', Object_Name, Object_Type
FROM observable_objects 
WHERE instrument = 'Space Telescope';

-- an example query with group by and having
-- display number of moons for each planet that has any moons
SELECT p.planet_name AS 'Planet', COUNT(*) AS NumberOfMoons FROM moons AS m
JOIN planets AS p ON m.planet_id = p.planet_id
GROUP BY p.planet_name
ORDER BY NumberOfMoons;

-- display all the moons that were discovered before the year 2000, or without a recorded date
SELECT m.IAU_name AS 'Name', p.planet_name AS 'Planet', m.year_discovered AS 'Discovered' FROM moons AS m
JOIN planets AS p ON m.planet_id = p.planet_id
HAVING (m.year_discovered < 2000 OR m.year_discovered IS NULL)
ORDER BY m.year_discovered;

-- display name & type of the planet, which has more than 1 moon and it's rotation period is more than Earth's 
SELECT p.planet_name AS 'Planet', p.planet_type AS 'Type of Planet' FROM planets AS p
WHERE p.rotation_period_hours > (SELECT rotation_period_hours FROM planets WHERE planet_name = 'Earth')
AND p.planet_id IN (SELECT m.planet_id FROM moons AS m GROUP BY m.planet_id HAVING COUNT(*) > 1);