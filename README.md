# Celestial Objects Database
<img width="1137" alt="Screenshot 2024-09-03 at 22 31 05" src="https://github.com/user-attachments/assets/b60c944d-b5dc-4a8e-8549-cfd9b1f044af">

## Project Overview

**Comprehensive Celestial Database**   
Create a database with multiple tables storing information about various celestial objects; including planets, their moons, stars, constellations and galaxies.

**Observational Instrumentation Record**  
Additional table to document the specific instruments required for observing each celestial object.

## Database Structure

<img width="963" alt="Screenshot 2024-09-06 at 22 56 48" src="https://github.com/user-attachments/assets/c9209567-8780-454d-be25-309ba74174f4">

The schema adheres to 3rd Normal Form (3NF), ensuring that it avoids redundancy and update anomalies.  

### <img width="40" alt="Solar system" src="https://github.com/user-attachments/assets/b5203c79-100c-4656-a0b2-4de7e023865c"> Planets  

Table containing facts about planets in our Solar System.  

Information included:   
- Planet Name	
- Planet Type
- Radius in km
- Rotation period around own axis in hours
- Orbital period around the Sun in Earth Days
- Distance from Sun in km
- Rings

### <img width="40" alt="moon" src="https://github.com/user-attachments/assets/43cdf225-f2db-407d-b8ec-63111d3574dd"> Moons 
Table containing facts about moons of the planets in our Solar System.  
Foreign key references the Planets table.  

Information included:  
- IAU name (International Astronomical Union)
- Provisional Designation (provisional name)
- Year Discovered

### <img width="40" alt="stars" src="https://github.com/user-attachments/assets/4e74d661-ed60-43d9-a6a9-4e25dc313e80"> Stars 
Table containing facts about stars from various constellations.  
Foreign key references the constellations table.  

Information included:  
- Common name
- Astronomical name
- Meaning of the name
- Apparent magnitude - brightness of stars as observed from Earth, the lower the number, the brighter the star
- Absolute magnitude - brightness as it would be seen at a standard distance of 10 parsecs (32.61 light years)
- Distance from Earth in light years  

### <img width="40" alt="constellation Orion" src="https://github.com/user-attachments/assets/e3078202-0a1d-4f11-857e-fc873d316ae4"> Constellations
Table containing facts about 88 modern constellations.  

Information included:  
- Constellation name
- English name
- Area (square degrees) - total angular area that the constellation covers in the sky when viewed from Earth
- Quadrant - a section of the celestial sphere divided based on the cardinal points (north, south, east, west)
- Visibility - the range of latitudes on Earth between which the constellation is visible, indicates how far north and south the constellation can be observed

### <img width="40" alt="galaxy" src="https://github.com/user-attachments/assets/2588b49e-43d3-41e2-87d4-69f71a774eb6"> Galaxies
Facts about stars from various constellations.   
Foreign key references the constellations table.  

Information included:  
- Galaxy name
- Meaning (names are often from Greek Mythology)  

### <img width="40" alt="telescope" src="https://github.com/user-attachments/assets/5192f532-5e45-4aec-b91c-8c9f31a6d67d"> Instrumentation
Stores various instruments used for space observation.  

Current options: 
- Naked Eye
- Amateur Telescope
- Observatory Telescope
- Space Telescope  

### Observability
Combines Planets, Moons, Stars, Galaxies and Constellations (object id & object type) with the Instrument that can be used to observe them.  
The table originally had a separate column for each object type, but was later changed to allow for easier object addition in the future (e.g.asterisms, black holes etc) without altering the table structure and to reduce data redundancy.   
Even though the new design might require more complex queries to retrieve specific data, I believe it will allow for more flexibility (you can store any object without changing the table structure) and simplicity (the structure is more generic and simpler).
Data is entered using stored procedure to verify object id exists in the referenced table and object type matches the object id. The procedure ignores any white spaces, as well as incorrect font. The data will be entered consistently for better readability of the output queries.  

## **Entities and Their Attributes**

1. **Planets**
   - **Attributes:** `id`, `planet_id`, `planet_name`, `planet_type`, `radius_km`, `rotation_period_hours`, `orbital_period_earth_days`, `distance_from_sun_km`, `rings`
   
2. **Moons**
   - **Attributes:** `id`, `moon_id`, `IAU_name`, `provisional_designation`, `year_discovered`, `planet_id`
   
3. **Constellations**
   - **Attributes:** `id`, `constellation_id`, `constellation_name`, `english_name`, `area_square_degrees`, `quadrant`, `visibility_degrees_North`, `visibility_degrees_South`
   
4. **Stars**
   - **Attributes:** `id`, `star_id`, `common_name`, `astronomical_name`, `meaning`, `apparent_magnitude`, `absolute_magnitude`, `distance_light_years`, `constellation_id`
   
5. **Galaxies**
   - **Attributes:** `id`, `galaxy_id`, `galaxy_name`, `constellation_id`
   
6. **Instrumentation**
   - **Attributes:** `instrument_id`, `instrument`
   
7. **Observability**
   - **Attributes:** `observability_id`, `instrument_id`, `object_id`, `object_type`

## **Relationships Between Entities**

1. **Planets and Moons**
   - **Type:** One-to-Many
   - **Description:** Each planet can have multiple moons, but each moon is associated with only one planet.
   - **Implementation:** The `moons` table includes a foreign key `planet_id` referencing `planets(planet_id)`.

2. **Constellations, Stars, and Galaxies**
   - **Constellations to Stars**
     - **Type:** One-to-Many
     - **Description:** Each constellation can contain multiple stars, but each star belongs to only one constellation.
     - **Implementation:** The `stars` table includes a foreign key `constellation_id` referencing `constellations(constellation_id)`.
   
   - **Constellations to Galaxies**
     - **Type:** One-to-Many
     - **Description:** Each constellation can encompass multiple galaxies (Constellations cover vast areas of the sky. As our telescopic technology advances, more galaxies are discovered within the same constellational boundaries. For example, the constellation Virgo is known for containing a large cluster of galaxies.), but each galaxy is associated with only one constellation.
     - **Implementation:** The `galaxies` table includes a foreign key `constellation_id` referencing `constellations(constellation_id)`.

3. **Instrumentation and Observability**
   - **Type:** Many-to-Many (Implemented via Observability Table)
   - **Description:** Each instrument can be used to observe multiple celestial objects, and each celestial object can be observed using multiple instruments.
   - **Implementation:** The `observability` table serves as a junction table with foreign keys `instrument_id` (referencing `instrumentation(instrument_id)`) and polymorphic keys `object_id` & `object_type` to reference any celestial object.

4. **Polymorphic Relationship in Observability**
   - **Description:** The `observability` table uses `object_id` and `object_type` to reference different types of celestial objects (`planets`, `moons`, `constellations`, `stars`, `galaxies`).
   - **Consideration:** This design introduces a polymorphic association, allowing flexibility to add new celestial object types without altering the table structure.

## Triggers
Used to update observability table in case a row from planets, moons, stars, constellations or galaxies is deleted.  

5 separate triggers to cover the planets, moons, stars, constellation and galaxies table.  

<img width="540" alt="Screenshot 2024-09-06 at 22 46 09" src="https://github.com/user-attachments/assets/70412946-c38c-4722-8bf9-98158aa0e93e">

## Views
2 stored views
1. Display names of all the stars, 
constellations and galaxies that 
are observable from London 
(latitude 51.5 N)
<img width="550" alt="Screenshot 2024-09-06 at 22 47 18" src="https://github.com/user-attachments/assets/62e677b8-6080-4b29-8259-7b70321caaf6">

2. A view joining observability table 
with planets, moons, stars, constellations, 
galaxies, instrumentation to display names
of objects
E.g.
```sql
SELECT ROW_NUMBER() OVER() AS 'Visible with Naked Eye ', Object_Name, Object_Type
FROM observable_objects 
WHERE instrument = 'Naked Eye';
```
<img width="400" alt="Screenshot 2024-09-06 at 22 48 17" src="https://github.com/user-attachments/assets/9d4f457a-de35-49b5-9dbd-2d3ee13187dd">

## Data source
Wikipedia  
NASA: https://science.nasa.gov/solar-system/planets/   
https://science.nasa.gov/solar-system/moons/facts/ 
https://littleastronomy.com/galaxy-names/  
https://www.constellation-guide.com/constellations/  
https://web.pa.msu.edu/people/horvatin/Astronomy_Facts/brightest_stars.html   

## Setup Instructions
1. Clone the repository.
   ```bash
   git clone https://github.com/nashetty/celestial-objects-database.git
   ```
2. Run the `space.sql` script to set up the database schema and populate the tables.
3. Use the `queries.sql` file to run example queries.

## Sample queries
```sql
-- Count number of stars visible from London (lat 51.5 N)
SELECT COUNT(*) FROM stars
WHERE constellation_id IN (SELECT constellation_id FROM constellations
WHERE visibility_degrees_North >= 51.5);
```

```sql
-- Retrieve all planets with their moons
SELECT p.planet_name, m.IAU_name
FROM planets p
JOIN moons m ON p.planet_id = m.planet_id;
```

```sql
-- Display the brightest star (or stars if tie) in each constellation 
-- NB. the lower the apparent_magnitude, the brighter the star
SELECT 
    c.constellation_name AS 'Constellation',
    s.common_name AS 'Brigtest Star',
    MIN(s.apparent_magnitude) AS 'Brigtness',
    s.meaning AS 'Star Name meaning' 
FROM stars AS s
JOIN constellations AS c ON c.constellation_id = s.constellation_id
WHERE s.apparent_magnitude = (SELECT MIN(apparent_magnitude) FROM stars WHERE constellation_id = c.constellation_id)
GROUP BY c.constellation_name, s.common_name, s.meaning
ORDER BY c.constellation_name;
```

```sql
-- display all the moons that were discovered before the year 2000, or without a recorded date
SELECT m.IAU_name AS 'Name', p.planet_name AS 'Planet', m.year_discovered AS 'Discovered' FROM moons AS m
JOIN planets AS p ON m.planet_id = p.planet_id
HAVING (m.year_discovered < 2000 OR m.year_discovered IS NULL)
ORDER BY m.year_discovered;
```

```sql
-- Display names of all the stars, constellations and galaxies that are observable from London (latitude 51.5 N)
SELECT ROW_NUMBER() OVER(ORDER BY s.id) AS number, common_name AS 'Stars Visible from London', constellation_name AS 'In Constellation', meaning FROM stars AS s
JOIN constellations AS c ON s.constellation_id = c.constellation_id
WHERE c.constellation_id IN (SELECT c.constellation_id FROM constellations AS c
WHERE c.visibility_degrees_North >= 51.5);
```

## Future Enhancements
- **Expand the database** to include other celestial objects like comets or asteroids.
- **Determine star visibility by location** to show which stars or constellations are visible from different cities or regions.
