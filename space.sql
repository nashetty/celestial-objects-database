CREATE DATABASE IF NOT EXISTS space;

USE space;

-- Table to store information about planets in Solar System
CREATE TABLE planets (
	id INT NOT NULL AUTO_INCREMENT, 
    planet_id VARCHAR(10) NOT NULL UNIQUE, 
    planet_name VARCHAR(50), 
    planet_type VARCHAR(50), 
    radius_km INT, 
    rotation_period_hours FLOAT(2), 
    orbital_period_earth_days FLOAT(2), 
    distance_from_sun_km BIGINT, 
    rings BOOL, 
    PRIMARY KEY (id)
);
    
-- Table to store information about the known Moons of the planets in our Solar System
-- with a foreign key referencing the planets table
CREATE TABLE moons (
	id INT NOT NULL AUTO_INCREMENT, 
    moon_id VARCHAR(10) NOT NULL UNIQUE, 
    IAU_name VARCHAR(50), -- International Astronomical Union (IAU)
    provisional_designation VARCHAR(50), -- Provisional name for the Moons
    year_discovered INT, 
    planet_id VARCHAR(10), 
    PRIMARY KEY (id), 
    CONSTRAINT fk_planet FOREIGN KEY (planet_id) REFERENCES planets(planet_id)
);
        
-- Table to store information about constellations
CREATE TABLE constellations (
	id INT NOT NULL AUTO_INCREMENT, 
	constellation_id VARCHAR(10) NOT NULL UNIQUE, 
    constellation_name VARCHAR(50), 
    english_name VARCHAR(50), 
    area_square_degrees FLOAT(3), -- total angular area that the constellation covers in the sky when viewed from Earth
    quadrant VARCHAR(5), -- a section of the celestial sphere divided based on the cardinal points (north, south, east, west
    visibility_degrees_North INT, --  the range of latitudes on Earth between which the constellation is visible
    visibility_degrees_South INT, -- indicates how far north and south the constellation can be observed
    PRIMARY KEY (id)
);

-- Table to store information about stars
-- with a foreign referencing the constellations table
CREATE TABLE stars (
	id INT NOT NULL AUTO_INCREMENT, 
    star_id VARCHAR(10) NOT NULL UNIQUE, 
    common_name VARCHAR(50), 
    astronomical_name VARCHAR(50), 
    meaning VARCHAR(255), 
    apparent_magnitude FLOAT(2), -- brightness of stars as observed from Earth, the lower the number, the brighter the star
    absolute_magnitude FLOAT(2), -- brightness as it would be seen at a standard distance of 10 parsecs (32.61 light years)
    distance_light_years FLOAT(2), 
    constellation_id VARCHAR(10), 
    PRIMARY KEY (id), 
    CONSTRAINT fk_constellation FOREIGN KEY (constellation_id) REFERENCES constellations(constellation_id)
);

-- Table to store information about galaxies
-- with a foreign key referencing the constellations table
CREATE TABLE galaxies (
	id INT NOT NULL AUTO_INCREMENT, 
	galaxy_id VARCHAR(10) NOT NULL UNIQUE, 
    galaxy_name VARCHAR(50),
    meaning VARCHAR(255),
    constellation_id VARCHAR(10), -- galaxy can be observed inside the area of the limits of the constellation
    PRIMARY KEY (id), 
    CONSTRAINT fk_near_constellations FOREIGN KEY (constellation_id) REFERENCES constellations(constellation_id)
);
        
-- Table to store various instruments used for observation
CREATE TABLE instrumentation (
	instrument_id INT NOT NULL AUTO_INCREMENT, 
	instrument VARCHAR(50), 
    PRIMARY KEY (instrument_id)
);

-- Stored procedure to validate the object type and object_id
DELIMITER //
CREATE PROCEDURE InsertObservabilityObject(
	IN instrument_id_value INT,
    IN object_id_value VARCHAR(10),
    IN object_type_value VARCHAR(50)
)
BEGIN
	DECLARE ValidatedObject BOOLEAN;
    -- remove white spaces from both inputs
    SET object_type_value = TRIM(object_type_value);
    SET object_id_value = TRIM(object_id_value);
    -- check if object type correct based on object id
	SET ValidatedObject = (
		(object_type_value = 'planet' AND object_id_value LIKE 'P%') OR
        (object_type_value = 'moon' AND object_id_value LIKE 'M%') OR
        (object_type_value = 'constellation' AND object_id_value LIKE 'C%') OR
        (object_type_value = 'star' AND object_id_value LIKE 'S%') OR
        (object_type_value = 'galaxy' AND object_id_value LIKE 'G%')
    );
    
    -- if object valid, check if it exists in any of the tables 
    IF ValidatedObject AND (
		EXISTS(SELECT 1 FROM planets WHERE planet_id = object_id_value) OR
        EXISTS(SELECT 1 FROM moons WHERE moon_id = object_id_value) OR
        EXISTS(SELECT 1 FROM constellations WHERE constellation_id = object_id_value) OR
        EXISTS(SELECT 1 FROM stars WHERE star_id = object_id_value) OR
        EXISTS(SELECT 1 FROM galaxies WHERE galaxy_id = object_id_value)
    )
    
    -- if both above conditions met, insert all the values into the observability table
	THEN
		INSERT INTO observability (instrument_id, object_id, object_type)
		VALUES (instrument_id_value, UPPER(object_id_value), LOWER(object_type_value));
    
    -- if object invalid, raise an error and notify user
    ELSE
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid object type or non existent object id';
	END IF;
END //

DELIMITER ;

-- Table to show which instrument can be used to observe which celestial object
CREATE TABLE observability (
	observability_id INT NOT NULL AUTO_INCREMENT, 
    instrument_id INT, 
    object_id VARCHAR(10), 
    object_type VARCHAR(50), 
    PRIMARY KEY (observability_id), 
    CONSTRAINT fk_instrument FOREIGN KEY (instrument_id) REFERENCES instrumentation(instrument_id)
);

-- Insert values into planets
-- data source: Wikipedia, NASA (https://science.nasa.gov/solar-system/planets/)
INSERT INTO planets(
	id, planet_id, planet_name, planet_type, radius_km, 
    rotation_period_hours, orbital_period_earth_days, 
    distance_from_sun_km, rings
)
VALUES 
(1, 'P1', 'Mercury', 'Terrestrial', 2440, 1410.1, 88, 58000000, FALSE),
(2, 'P2', 'Venus', 'Terrestrial', 6052, 5807.7, 225, 108000000, FALSE),
(3, 'P3', 'Earth', 'Terrestrial', 6371, 23.9, 365.25, 150000000, FALSE),
(4, 'P4', 'Mars', 'Terrestrial', 3390, 24.6, 687, 228000000, FALSE),
(5, 'P5', 'Jupiter', 'Gas giant', 69911, 10, 4333, 778000000, TRUE),
(6, 'P6', 'Saturn', 'Gas giant', 58232, 10.7, 10756, 1400000000, TRUE),
(7, 'P7', 'Uranus', 'Ice giant', 25362, 17, 30687, 2900000000, TRUE),
(8, 'P8', 'Neptune', 'Ice giant', 24622, 16, 60190, 4500000000, TRUE),
(9, 'P9', 'Pluto', 'Dwarf planet', 1151, 153, 90582, 5900000000, FALSE),
(10, 'P10', 'Ceres', 'Dwarf planet', 476, 9, 1682, 413000000, FALSE),
(11, 'P11', 'Makemake', 'Dwarf planet', 715, 22.5, 111401.25, 6847000000, FALSE),
(12, 'P12', 'Haumea', 'Dwarf planet', 620, 4, 285, 6452000000, TRUE),
(13, 'P13', 'Eris', 'Dwarf planet', 1163, 25.9, 203444.25, 10125000000, FALSE),
(14, 'P14', 'Sedna', 'Dwarf planet', 498, 10.25, 4163850, 13000000000, NULL);

-- Instert values into moons table
-- data source: Wikipedia, NASA https://science.nasa.gov/solar-system/moons/facts/
INSERT INTO moons(
	id, moon_id, IAU_name, provisional_designation, year_discovered, planet_id
)
VALUES
(1, 'M1', 'The Moon', NULL, NULL, 'P3'),
(2, 'M2', 'Phobos', NULL, 1877, 'P4'),
(3, 'M3', 'Deimos', NULL, 1877, 'P4'),
(4, 'M4', 'Io', NULL, 1610, 'P5'),
(5, 'M5', 'Europa', NULL, 1610, 'P5'),
(6, 'M6', 'Ganymede', NULL, 1610, 'P5'),
(7, 'M7', 'Callisto', NULL, 1610, 'P5'),
(8, 'M8', 'Amalthea', NULL, 1892, 'P5'),
(9, 'M9', 'Himalia', NULL, 1904, 'P5'),
(10, 'M10', 'Elara', NULL, 1905, 'P5'),
(11, 'M11', 'Pasiphae', NULL, 1908, 'P5'),
(12, 'M12', 'Sinope', NULL, 1914, 'P5'),
(13, 'M13', 'Lysithea', NULL, 1938, 'P5'),
(14, 'M14', 'Carme', NULL, 1938, 'P5'),
(15, 'M15', 'Ananke', NULL, 1951, 'P5'),
(16, 'M16', 'Leda', NULL, 1974, 'P5'),
(17, 'M17', 'Thebe', 'S/1979 J2', 1979, 'P5'),
(18, 'M18', 'Adrastea', 'S/1979 J1', 1979, 'P5'),
(19, 'M19', 'Metis', 'S/1979 J3', 1979, 'P5'),
(20, 'M20', 'Callirrhoe', 'S/1999 J1', 1999, 'P5'),
(21, 'M21', 'Themisto', 'S/1975 J1 = S/2000 J1', 1975, 'P5'),
(22, 'M22', 'Megaclite', 'S/2000 J8', 2000, 'P5'),
(23, 'M23', 'Taygete', 'S/2000 J9', 2000, 'P5'),
(24, 'M24', 'Chaldene', 'S/2000 J10', 2000, 'P5'),
(25, 'M25', 'Harpalyke', 'S/2000 J5', 2000, 'P5'),
(26, 'M26', 'Kalyke', 'S/2000 J2', 2000, 'P5'),
(27, 'M27', 'Iocaste', 'S/2000 J3', 2000, 'P5'),
(28, 'M28', 'Erinome', 'S/2000 J4', 2000, 'P5'),
(29, 'M29', 'Isonoe', 'S/2000 J6', 2000, 'P5'),
(30, 'M30', 'Praxidike', 'S/2000 J7', 2000, 'P5'),
(31, 'M31', 'Autonoe', 'S/2001 J1', 2001, 'P5'),
(32, 'M32', 'Thyone', 'S/2001 J2', 2001, 'P5'),
(33, 'M33', 'Hermippe', 'S/2001 J3', 2001, 'P5'),
(34, 'M34', 'Aitne', 'S/2001 J11', 2001, 'P5'),
(35, 'M35', 'Eurydome', 'S/2001 J4', 2001, 'P5'),
(36, 'M36', 'Euanthe', 'S/2001 J7', 2001, 'P5'),
(37, 'M37', 'Euporie', 'S/2001 J10', 2001, 'P5'),
(38, 'M38', 'Orthosie', 'S/2001 J9', 2001, 'P5'),
(39, 'M39', 'Sponde', 'S/2001 J5', 2001, 'P5'),
(40, 'M40', 'Kale', 'S/2001 J8', 2001, 'P5'),
(41, 'M41', 'Pasithee', 'S/2001 J6', 2001, 'P5'),
(42, 'M42', 'Hegemone', 'S/2003 J8', 2003, 'P5'),
(43, 'M43', 'Mneme', 'S/2003 J21', 2003, 'P5'),
(44, 'M44', 'Aoede', 'S/2003 J7', 2003, 'P5'),
(45, 'M45', 'Thelxinoe', 'S/2003 J22', 2003, 'P5'),
(46, 'M46', 'Arche', 'S/2002 J1', 2002, 'P5'),
(47, 'M47', 'Kallichore', 'S/2003 J11', 2003, 'P5'),
(48, 'M48', 'Helike', 'S/2003 J6', 2003, 'P5'),
(49, 'M49', 'Carpo', 'S/2003 J20', 2003, 'P5'),
(50, 'M50', 'Eukelade', 'S/2003 J1', 2003, 'P5'),
(51, 'M51', 'Cyllene', 'S/2003 J13', 2003, 'P5'),
(52, 'M52', 'Kore', 'S/2003 J14', 2003, 'P5'),
(53, 'M53', 'Herse', 'S/2003 J17', 2003, 'P5'),
(54, 'M54', NULL, 'S/2010 J1', 2010, 'P5'),
(55, 'M55', NULL, 'S/2010 J2', 2010, 'P5'),
(56, 'M56', 'Dia', 'S/2000 J11', 2000, 'P5'),
(57, 'M57', NULL, 'S/2016 J1', 2016, 'P5'),
(58, 'M58', NULL, 'S/2003 J18', 2003, 'P5'),
(59, 'M59', NULL, 'S/2011 J2', 2011, 'P5'),
(60, 'M60', 'Eirene', 'S/2003 J5', 2003, 'P5'),
(61, 'M61', 'Philophrosyne', 'S/2003 J15', 2003, 'P5'),
(62, 'M62', NULL, 'S/2017 J1', 2017, 'P5'),
(63, 'M63', 'Eupheme', 'S/2003 J3', 2003, 'P5'),
(64, 'M64', NULL, 'S/2003 J19', 2003, 'P5'),
(65, 'M65', 'Valetudo', 'S/2016 J2', 2016, 'P5'),
(66, 'M66', NULL, 'S/2017 J2', 2017, 'P5'),
(67, 'M67', NULL, 'S/2017 J3', 2017, 'P5'),
(68, 'M68', 'Pandia', 'S/2017 J4', 2017, 'P5'),
(69, 'M69', NULL, 'S/2017 J5', 2017, 'P5'),
(70, 'M70', NULL, 'S/2017 J6', 2017, 'P5'),
(71, 'M71', NULL, 'S/2017 J7', 2017, 'P5'),
(72, 'M72', NULL, 'S/2017 J8', 2017, 'P5'),
(73, 'M73', NULL, 'S/2017 J9', 2017, 'P5'),
(74, 'M74', 'Ersa', 'S/2018 J1', 2018, 'P5'),
(75, 'M75', NULL, 'S/2011 J1', 2011, 'P5'),
(76, 'M76', NULL, 'S/2003 J2', 2003, 'P5'),
(77, 'M77', NULL, 'S/2003 J4', 2003, 'P5'),
(78, 'M78', NULL, 'S/2003 J9', 2003, 'P5'),
(79, 'M79', NULL, 'S/2003 J10', 2003, 'P5'),
(80, 'M80', NULL, 'S/2003 J12', 2003, 'P5'),
(81, 'M81', NULL, 'S/2003 J16', 2003, 'P5'),
(82, 'M82', NULL, 'S/2003 J23', 2003, 'P5'),
(83, 'M83', NULL, 'S/2003 J24', 2003, 'P5'),
(84, 'M84', NULL, 'S/2011 J3', 2011, 'P5'),
(85, 'M85', NULL, 'S/2016 J3', 2016, 'P5'),
(86, 'M86', NULL, 'S/2016 J4', 2016, 'P5'),
(87, 'M87', NULL, 'S/2018 J2', 2018, 'P5'),
(88, 'M88', NULL, 'S/2018 J3', 2018, 'P5'),
(89, 'M89', NULL, 'S/2018 J4', 2018, 'P5'),
(90, 'M90', NULL, 'S/2021 J1', 2021, 'P5'),
(91, 'M91', NULL, 'S/2021 J2', 2021, 'P5'),
(92, 'M92', NULL, 'S/2021 J3', 2021, 'P5'),
(93, 'M93', NULL, 'S/2021 J4', 2021, 'P5'),
(94, 'M94', NULL, 'S/2021 J5', 2021, 'P5'),
(95, 'M95', NULL, 'S/2021 J6', 2021, 'P5'),
(96, 'M96', NULL, 'S/2022 J1', 2022, 'P5'),
(97, 'M97', NULL, 'S/2022 J2', 2022, 'P5'),
(98, 'M98', NULL, 'S/2022 J3', 2022, 'P5'),
(99, 'M99', 'Mimas', NULL, 1789, 'P6'),
(100, 'M100', 'Enceladus', NULL, 1789, 'P6'),
(101, 'M101', 'Tethys', NULL, 1684, 'P6'),
(102, 'M102', 'Dione', NULL, 1684, 'P6'),
(103, 'M103', 'Rhea', NULL, 1672, 'P6'),
(104, 'M104', 'Titan', NULL, 1655, 'P6'),
(105, 'M105', 'Hyperion', NULL, 1848, 'P6'),
(106, 'M106', 'Iapetus', NULL, 1671, 'P6'),
(107, 'M107', 'Phoebe', NULL, 1898, 'P6'),
(108, 'M108', 'Janus', 'S/1980 S1', 1966, 'P6'),
(109, 'M109', 'Epimetheus', 'S/1980 S3', 1977, 'P6'),
(110, 'M110', 'Helene', 'S/1980 S6', 1980, 'P6'),
(111, 'M111', 'Telesto', 'S/1980 S13', 1980, 'P6'),
(112, 'M112', 'Calypso', 'S/1980 S25', 1980, 'P6'),
(113, 'M113', 'Atlas', 'S/1980 S28', 1980, 'P6'),
(114, 'M114', 'Prometheus', 'S/1980 S27', 1980, 'P6'),
(115, 'M115', 'Pandora', 'S/1980 S26', 1980, 'P6'),
(116, 'M116', 'Pan', 'S/1981 S13', 1990, 'P6'),
(117, 'M117', 'Ymir', 'S/2000 S1', 2000, 'P6'),
(118, 'M118', 'Paaliaq', 'S/2000 S2', 2000, 'P6'),
(119, 'M119', 'Tarvos', 'S/2000 S4', 2000, 'P6'),
(120, 'M120', 'Ijiraq', 'S/2000 S6', 2000, 'P6'),
(121, 'M121', 'Suttungr', 'S/2000 S12', 2000, 'P6'),
(122, 'M122', 'Kiviuq', 'S/2000 S5', 2000, 'P6'),
(123, 'M123', 'Mundilfari', 'S/2000 S9', 2000, 'P6'),
(124, 'M124', 'Albiorix', 'S/2000 S11', 2000, 'P6'),
(125, 'M125', 'Skathi', 'S/2000 S8', 2000, 'P6'),
(126, 'M126', 'Erriapus', 'S/2000 S10', 2000, 'P6'),
(127, 'M127', 'Siarnaq', 'S/2000 S3', 2000, 'P6'),
(128, 'M128', 'Thrymr', 'S/2000 S7', 2000, 'P6'),
(129, 'M129', 'Narvi', 'S/2003 S1', 2003, 'P6'),
(130, 'M130', 'Methone', 'S/2004 S1', 2004, 'P6'),
(131, 'M131', 'Pallene', 'S/2004 S2', 2004, 'P6'),
(132, 'M132', 'Polydeuces', 'S/2004 S5', 2004, 'P6'),
(133, 'M133', 'Daphnis', 'S/2005 S1', 2005, 'P6'),
(134, 'M134', 'Aegir', 'S/2004 S10', 2004, 'P6'),
(135, 'M135', 'Bebhionn', 'S/2004 S11', 2004, 'P6'),
(136, 'M136', 'Bergelmir', 'S/2004 S15', 2004, 'P6'),
(137, 'M137', 'Bestla', 'S/2004 S18', 2004, 'P6'),
(138, 'M138', 'Farbauti', 'S/2004 S9', 2004, 'P6'),
(139, 'M139', 'Fenrir', 'S/2004 S16', 2004, 'P6'),
(140, 'M140', 'Fornjot', 'S/2004 S8', 2004, 'P6'),
(141, 'M141', 'Hati', 'S/2004 S14', 2004, 'P6'),
(142, 'M142', 'Hyrrokkin', 'S/2004 S19', 2004, 'P6'),
(143, 'M143', 'Kari', 'S/2006 S2', 2006, 'P6'),
(144, 'M144', 'Loge', 'S/2006 S5', 2006, 'P6'),
(145, 'M145', 'Skoll', 'S/2006 S8', 2006, 'P6'),
(146, 'M146', 'Surtur', 'S/2006 S7', 2006, 'P6'),
(147, 'M147', 'Anthe', 'S/2007 S4', 2007, 'P6'),
(148, 'M148', 'Jarnsaxa', 'S/2006 S6', 2006, 'P6'),
(149, 'M149', 'Greip', 'S/2006 S4', 2006, 'P6'),
(150, 'M150', 'Tarqeq', 'S/2007 S1', 2007, 'P6'),
(151, 'M151', 'Aegaeon', 'S/2008 S1', 2008, 'P6'),
(152, 'M152', 'Gridr', 'S/2004 S20', 2004, 'P6'),
(153, 'M153', 'Angrboda', 'S/2004 S22', 2004, 'P6'),
(154, 'M154', 'Skrymir', 'S/2004 S23', 2004, 'P6'),
(155, 'M155', 'Gerd', 'S/2004 S25', 2004, 'P6'),
(156, 'M156', NULL, 'S/2004 S26', 2004, 'P6'),
(157, 'M157', 'Eggther', 'S/2004 S27', 2004, 'P6'),
(158, 'M158', NULL, 'S/2004 S29', 2004, 'P6'),
(159, 'M159', 'Beli', 'S/2004 S30', 2004, 'P6'),
(160, 'M160', 'Gunnlod', 'S/2004 S32', 2004, 'P6'),
(161, 'M161', 'Thiazzi', 'S/2004 S33', 2004, 'P6'),
(162, 'M162', NULL, 'S/2004 S34', 2004, 'P6'),
(163, 'M163', 'Alvaldi', 'S/2004 S35', 2004, 'P6'),
(164, 'M164', 'Geirrod', 'S/2004 S38', 2004, 'P6'),
(165, 'M165', NULL, 'S/2004 S7', 2005, 'P6'),
(166, 'M166', NULL, 'S/2004 S12', 2005, 'P6'),
(167, 'M167', NULL, 'S/2004 S13', 2005, 'P6'),
(168, 'M168', NULL, 'S/2004 S17', 2005, 'P6'),
(169, 'M169', NULL, 'S/2004 S21', 2004, 'P6'),
(170, 'M170', NULL, 'S/2004 S24', 2004, 'P6'),
(171, 'M171', NULL, 'S/2004 S28', 2004, 'P6'),
(172, 'M172', NULL, 'S/2004 S31', 2004, 'P6'),
(173, 'M173', NULL, 'S/2004 S36', 2004, 'P6'),
(174, 'M174', NULL, 'S/2004 S37', 2004, 'P6'),
(175, 'M175', NULL, 'S/2004 S39', 2004, 'P6'),
(176, 'M176', NULL, 'S/2004 S40', 2004, 'P6'),
(177, 'M177', NULL, 'S/2004 S41', 2004, 'P6'),
(178, 'M178', NULL, 'S/2004 S42', 2004, 'P6'),
(179, 'M179', NULL, 'S/2004 S43', 2004, 'P6'),
(180, 'M180', NULL, 'S/2004 S44', 2004, 'P6'),
(181, 'M181', NULL, 'S/2004 S45', 2004, 'P6'),
(182, 'M182', NULL, 'S/2004 S46', 2004, 'P6'),
(183, 'M183', NULL, 'S/2004 S47', 2004, 'P6'),
(184, 'M184', NULL, 'S/2004 S48', 2004, 'P6'),
(185, 'M185', NULL, 'S/2004 S49', 2004, 'P6'),
(186, 'M186', NULL, 'S/2004 S50', 2004, 'P6'),
(187, 'M187', NULL, 'S/2004 S51', 2004, 'P6'),
(188, 'M188', NULL, 'S/2004 S52', 2004, 'P6'),
(189, 'M189', NULL, 'S/2004 S53', 2004, 'P6'),
(190, 'M190', NULL, 'S/2005 S4', 2005, 'P6'),
(191, 'M191', NULL, 'S/2005 S5', 2005, 'P6'),
(192, 'M192', NULL, 'S/2006 S1', 2006, 'P6'),
(193, 'M193', NULL, 'S/2006 S3', 2006, 'P6'),
(194, 'M194', NULL, 'S/2006 S9', 2006, 'P6'),
(195, 'M195', NULL, 'S/2006 S10', 2006, 'P6'),
(196, 'M196', NULL, 'S/2006 S11', 2006, 'P6'),
(197, 'M197', NULL, 'S/2006 S12', 2006, 'P6'),
(198, 'M198', NULL, 'S/2006 S13', 2006, 'P6'),
(199, 'M199', NULL, 'S/2006 S14', 2006, 'P6'),
(200, 'M200', NULL, 'S/2006 S15', 2006, 'P6'),
(201, 'M201', NULL, 'S/2006 S16', 2006, 'P6'),
(202, 'M202', NULL, 'S/2006 S17', 2006, 'P6'),
(203, 'M203', NULL, 'S/2006 S18', 2006, 'P6'),
(204, 'M204', NULL, 'S/2006 S19', 2006, 'P6'),
(205, 'M205', NULL, 'S/2006 S20', 2006, 'P6'),
(206, 'M206', NULL, 'S/2007 S2', 2007, 'P6'),
(207, 'M207', NULL, 'S/2007 S3', 2007, 'P6'),
(208, 'M208', NULL, 'S/2007 S5', 2007, 'P6'),
(209, 'M209', NULL, 'S/2007 S6', 2007, 'P6'),
(210, 'M210', NULL, 'S/2007 S7', 2007, 'P6'),
(211, 'M211', NULL, 'S/2007 S8', 2007, 'P6'),
(212, 'M212', NULL, 'S/2007 S9', 2007, 'P6'),
(213, 'M213', NULL, 'S/2009 S1', 2009, 'P6'),
(214, 'M214', NULL, 'S/2019 S1', 2019, 'P6'),
(215, 'M215', NULL, 'S/2019 S2', 2019, 'P6'),
(216, 'M216', NULL, 'S/2019 S3', 2019, 'P6'),
(217, 'M217', NULL, 'S/2019 S4', 2019, 'P6'),
(218, 'M218', NULL, 'S/2019 S5', 2019, 'P6'),
(219, 'M219', NULL, 'S/2019 S6', 2019, 'P6'),
(220, 'M220', NULL, 'S/2019 S7', 2019, 'P6'),
(221, 'M221', NULL, 'S/2019 S8', 2019, 'P6'),
(222, 'M222', NULL, 'S/2019 S9', 2019, 'P6'),
(223, 'M223', NULL, 'S/2019 S10', 2019, 'P6'),
(224, 'M224', NULL, 'S/2019 S11', 2019, 'P6'),
(225, 'M225', NULL, 'S/2019 S12', 2019, 'P6'),
(226, 'M226', NULL, 'S/2019 S13', 2019, 'P6'),
(227, 'M227', NULL, 'S/2019 S14', 2019, 'P6'),
(228, 'M228', NULL, 'S/2019 S15', 2019, 'P6'),
(229, 'M229', NULL, 'S/2019 S16', 2019, 'P6'),
(230, 'M230', NULL, 'S/2019 S17', 2019, 'P6'),
(231, 'M231', NULL, 'S/2019 S18', 2019, 'P6'),
(232, 'M232', NULL, 'S/2019 S19', 2019, 'P6'),
(233, 'M233', NULL, 'S/2019 S20', 2019, 'P6'),
(234, 'M234', NULL, 'S/2019 S21', 2019, 'P6'),
(235, 'M235', NULL, 'S/2020 S1', 2020, 'P6'),
(236, 'M236', NULL, 'S/2020 S2', 2020, 'P6'),
(237, 'M237', NULL, 'S/2020 S3', 2020, 'P6'),
(238, 'M238', NULL, 'S/2020 S4', 2020, 'P6'),
(239, 'M239', NULL, 'S/2020 S5', 2020, 'P6'),
(240, 'M240', NULL, 'S/2020 S6', 2020, 'P6'),
(241, 'M241', NULL, 'S/2020 S7', 2020, 'P6'),
(242, 'M242', NULL, 'S/2020 S8', 2020, 'P6'),
(243, 'M243', NULL, 'S/2020 S9', 2020, 'P6'),
(244, 'M244', NULL, 'S/2020 S10', 2020, 'P6'),
(245, 'M245', 'Ariel', NULL, 1851, 'P7'),
(246, 'M246', 'Umbriel', NULL, 1851, 'P7'),
(247, 'M247', 'Titania', NULL, 1787, 'P7'),
(248, 'M248', 'Oberon', NULL, 1787, 'P7'),
(249, 'M249', 'Miranda', NULL, 1948, 'P7'),
(250, 'M250', 'Cordelia', 'S/1986 U7', 1986, 'P7'),
(251, 'M251', 'Ophelia', 'S/1986 U8', 1986, 'P7'),
(252, 'M252', 'Bianca', 'S/1986 U9', 1986, 'P7'),
(253, 'M253', 'Cressida', 'S/1986 U3', 1986, 'P7'),
(254, 'M254', 'Desdemona', 'S/1986 U6', 1986, 'P7'),
(255, 'M255', 'Juliet', 'S/1986 U2', 1986, 'P7'),
(256, 'M256', 'Portia', 'S/1986 U1', 1986, 'P7'),
(257, 'M257', 'Rosalind', 'S/1986 U4', 1986, 'P7'),
(258, 'M258', 'Belinda', 'S/1986 U5', 1986, 'P7'),
(259, 'M259', 'Puck', 'S/1985 U1', 1985, 'P7'),
(260, 'M260', 'Caliban', 'S/1997 U1', 1997, 'P7'),
(261, 'M261', 'Sycorax', 'S/1997 U2', 1997, 'P7'),
(262, 'M262', 'Prospero', 'S/1999 U3', 1999, 'P7'),
(263, 'M263', 'Setebos', 'S/1999 U1', 1999, 'P7'),
(264, 'M264', 'Stephano', 'S/1999 U2', 1999, 'P7'),
(265, 'M265', 'Trinculo', 'S/2001 U1', 2001, 'P7'),
(266, 'M266', 'Francisco', 'S/2001 U3', 2001, 'P7'),
(267, 'M267', 'Margaret', 'S/2003 U3', 2003, 'P7'),
(268, 'M268', 'Ferdinand', 'S/2001 U2', 2001, 'P7'),
(269, 'M269', 'Perdita', 'S/1986 U10', 1986, 'P7'),
(270, 'M270', 'Mab', 'S/2003 U1', 2003, 'P7'),
(271, 'M271', 'Cupid', 'S/2003 U2', 2003, 'P7'),
(272, 'M272', 'Triton', NULL, 1846, 'P8'),
(273, 'M273', 'Nereid', NULL, 1949, 'P8'),
(274, 'M274', 'Naiad', 'S/1989 N6', 1989, 'P8'),
(275, 'M275', 'Thalassa', 'S/1989 N5', 1989, 'P8'),
(276, 'M276', 'Despina', 'S/1989 N3', 1989, 'P8'),
(277, 'M277', 'Galatea', 'S/1989 N4', 1989, 'P8'),
(278, 'M278', 'Larissa', 'S/1989 N2', 1989, 'P8'),
(279, 'M279', 'Proteus', 'S/1989 N1', 1989, 'P8'),
(280, 'M280', 'Halimede', 'S/2002 N1', 2002, 'P8'),
(281, 'M281', 'Psamathe', 'S/2003 N1', 2003, 'P8'),
(282, 'M282', 'Sao', 'S/2002 N2', 2002, 'P8'),
(283, 'M283', 'Laomedeia', 'S/2002 N3', 2002, 'P8'),
(284, 'M284', 'Neso', 'S/2002 N4', 2002, 'P8'),
(285, 'M285', 'Hippocamp', 'S/2004 N1', 2013, 'P8'),
(286, 'M286', 'Charon', 'S/1978 P1', 1978, 'P9'),
(287, 'M287', 'Nix', 'S/2005 P2', 2005, 'P9'),
(288, 'M288', 'Hydra', 'S/2005 P1', 2005, 'P9'),
(289, 'M289', 'Kerberos', 'S/2011 (134340) 1', 2011, 'P9'),
(290, 'M290', 'Styx', 'S/2012 (134340) 1', 2012, 'P9'),
(291, 'M291', 'MK 2', 'S/2015 (136472)', 2015, 'P11'),
(292, 'M292', 'Namaka', 'S/2005 (2003 EL61) 2', 2005, 'P12'),
(293, 'M293', "Hi'iaka", 'S/2005 (2003 EL61) 1', 2005, 'P12'),
(294, 'M294', 'Dysnomia', 'S/2005 (2003 UB313)', 2005, 'P13');

-- Insert values into constellations table
-- data source https://www.constellation-guide.com/constellations/
INSERT INTO constellations (
	id, constellation_id, constellation_name, english_name, area_square_degrees, 
    quadrant, visibility_degrees_North, visibility_degrees_South
)
VALUES
(1, 'C1', 'Andromeda', 'Andromeda', 722.278, 'NQ1', 90, 40),
(2, 'C2', 'Antlia', 'Air Pump', 238.901, 'SQ2', 45, 90),
(3, 'C3', 'Apus', 'Bird of Paradise', 206.327, 'SQ3', 5, 90),
(4, 'C4', 'Aquarius', 'Water Bearer', 979.854, 'SQ4', 65, 90),
(5, 'C5', 'Aquila', 'Eagle', 652.473, 'NQ4', 90, 75),
(6, 'C6', 'Ara', 'Altar', 237.057, 'SQ3', 25, 90),
(7, 'C7', 'Aries', 'Ram', 441.395, 'NQ1', 90, 60),
(8, 'C8', 'Auriga', 'Charioteer', 657.438, 'NQ2', 90, 40),
(9, 'C9', 'Boötes', 'Herdsman', 906.831, 'NQ3', 90, 50),
(10, 'C10', 'Caelum', 'Chisel', 124.865, 'SQ1', 40, 90),
(11, 'C11', 'Camelopardalis', 'Giraffe', 756.828, 'NQ2', 90, 10),
(12, 'C12', 'Cancer', 'Crab', 505.872, 'NQ2', 90, 60),
(13, 'C13', 'Canes Venatici', 'Hunting Dogs', 465.194, 'NQ3', 90, 40),
(14, 'C14', 'Canis Major', 'Greater Dog', 380.118, 'SQ2', 60, 90),
(15, 'C15', 'Canis Minor', 'Lesser Dog', 183.367, 'NQ2', 90, 75),
(16, 'C16', 'Capricornus', 'Sea Goat', 413.947, 'SQ4', 60, 90),
(17, 'C17', 'Carina', 'Keel', 494.184, 'SQ2', 20, 90),
(18, 'C18', 'Cassiopeia', 'Cassiopeia', 598.407, 'NQ1', 90, 20),
(19, 'C19', 'Centaurus', 'Centaur', 1060.422, 'SQ3', 25, 90),
(20, 'C20', 'Cepheus', 'Cepheus', 587.787, 'NQ4', 90, 10),
(21, 'C21', 'Cetus', 'Whale (or Sea Monster)', 1231.411, 'SQ1', 70, 90),
(22, 'C22', 'Chamaeleon', 'Chameleon', 131.592, 'SQ2', 0, 90),
(23, 'C23', 'Circinus', 'Compass (drafting tool)', 93.353, 'SQ3', 30, 90),
(24, 'C24', 'Columba', 'Dove', 270.184, 'SQ1', 45, 90),
(25, 'C25', 'Coma Berenices', 'Berenice’s Hair', 386.475, 'NQ3', 90, 70),
(26, 'C26', 'Corona Australis', 'Southern Crown', 127.696, 'SQ4', 40, 90),
(27, 'C27', 'Corona Borealis', 'Northern Crown', 178.71, 'NQ3', 90, 50),
(28, 'C28', 'Corvus', 'Crow', 183.801, 'SQ3', 60, 90),
(29, 'C29', 'Crater', 'Cup', 282.398, 'SQ2', 65, 90),
(30, 'C30', 'Crux', 'Southern Cross', 68.447, 'SQ3', 20, 90),
(31, 'C31', 'Cygnus', 'Swan', 803.983, 'NQ4', 90, 40),
(32, 'C32', 'Delphinus', 'Dolphin', 188.549, 'NQ4', 90, 70),
(33, 'C33', 'Dorado', 'Dolphinfish', 179.173, 'SQ1', 20, 90),
(34, 'C34', 'Draco', 'Dragon', 1082.952, 'NQ3', 90, 15),
(35, 'C35', 'Equuleus', 'Little Horse (Foal)', 71.641, 'NQ4', 90, 80),
(36, 'C36', 'Eridanus', 'Eridanus (river)', 1137.919, 'SQ1', 32, 90),
(37, 'C37', 'Fornax', 'Furnace', 397.502, 'SQ1', 50, 90),
(38, 'C38', 'Gemini', 'Twins', 513.761, 'NQ2', 90, 60),
(39, 'C39', 'Grus', 'Crane', 365.513, 'SQ4', 34, 90),
(40, 'C40', 'Hercules', 'Hercules', 1225.148, 'NQ3', 90, 50),
(41, 'C41', 'Horologium', 'Pendulum Clock', 248.885, 'SQ1', 30, 90),
(42, 'C42', 'Hydra', 'Hydra', 1302.844, 'SQ2', 54, 83),
(43, 'C43', 'Hydrus', '(male) Water Snake', 243.035, 'SQ1', 8, 90),
(44, 'C44', 'Indus', 'Indian', 294.006, 'SQ4', 15, 90),
(45, 'C45', 'Lacerta', 'Lizard', 200.688, 'NQ4', 90, 40),
(46, 'C46', 'Leo', 'Lion', 946.964, 'NQ2', 90, 65),
(47, 'C47', 'Leo Minor', 'Lesser Lion', 231.956, 'NQ2', 90, 45),
(48, 'C48', 'Lepus', 'Hare', 290.291, 'SQ1', 63, 90),
(49, 'C49', 'Libra', 'Scales', 538.052, 'SQ3', 65, 90),
(50, 'C50', 'Lupus', 'Wolf', 333.683, 'SQ3', 35, 90),
(51, 'C51', 'Lynx', 'Lynx', 545.386, 'NQ2', 90, 55),
(52, 'C52', 'Lyra', 'Lyre', 286.476, 'NQ4', 90, 40),
(53, 'C53', 'Mensa', 'Table Mountain (Mons Mensae)', 153.484, 'SQ1', 4, 90),
(54, 'C54', 'Microscopium', 'Microscope', 209.513, 'SQ4', 45, 90),
(55, 'C55', 'Monoceros', 'Unicorn', 481.569, 'NQ2', 75, 90),
(56, 'C56', 'Musca', 'Fly', 138.355, 'SQ3', 10, 90),
(57, 'C57', 'Norma', 'Level', 165.29, 'SQ3', 30, 90),
(58, 'C58', 'Octans', 'Octant', 291.045, 'SQ4', 0, 90),
(59, 'C59', 'Ophiuchus', 'Serpent Bearer', 948.34, 'SQ3', 80, 80),
(60, 'C60', 'Orion', 'Orion (the Hunter)', 594.12, 'NQ1', 85, 75),
(61, 'C61', 'Pavo', 'Peacock', 377.666, 'SQ4', 30, 90),
(62, 'C62', 'Pegasus', 'Pegasus', 1120.794, 'NQ4', 90, 60),
(63, 'C63', 'Perseus', 'Perseus', 614.997, 'NQ1', 90, 35),
(64, 'C64', 'Phoenix', 'Phoenix', 469.319, 'SQ1', 32, 80),
(65, 'C65', 'Pictor', 'Easel', 246.739, 'SQ1', 26, 90),
(66, 'C66', 'Pisces', 'Fishes', 889.417, 'NQ1', 90, 65),
(67, 'C67', 'Piscis Austrinus', 'Southern Fish', 245.375, 'SQ4', 55, 90),
(68, 'C68', 'Puppis', 'Stern', 673.434, 'SQ2', 40, 90),
(69, 'C69', 'Pyxis', 'Compass (mariner’s compass)', 220.833, 'SQ2', 50, 90),
(70, 'C70', 'Reticulum', 'Reticle', 113.936, 'SQ1', 23, 90),
(71, 'C71', 'Sagitta', 'Arrow', 79.932, 'NQ4', 90, 70),
(72, 'C72', 'Sagittarius', 'Archer', 867.432, 'SQ4', 55, 90),
(73, 'C73', 'Scorpius', 'Scorpion', 496.783, 'SQ3', 40, 90),
(74, 'C74', 'Sculptor', 'Sculptor', 474.764, 'SQ1', 50, 90),
(75, 'C75', 'Scutum', 'Shield (of Sobieski)', 109.114, 'SQ4', 80, 90),
(76, 'C76', 'Serpens', 'Snake', 636.928, 'NQ3', 80, 80),
(77, 'C77', 'Sextans', 'Sextant', 313.515, 'SQ2', 80, 90),
(78, 'C78', 'Taurus', 'Bull', 797.249, 'NQ1', 90, 65),
(79, 'C79', 'Telescopium', 'Telescope', 251.512, 'SQ4', 40, 90),
(80, 'C80', 'Triangulum', 'Triangle', 131.847, 'NQ1', 90, 60),
(81, 'C81', 'Triangulum Australe', 'Southern Triangle', 109.978, 'SQ3', 25, 90),
(82, 'C82', 'Tucana', 'Toucan', 294.557, 'SQ4', 25, 90),
(83, 'C83', 'Ursa Major', 'Great Bear', 1279.66, 'NQ2', 90, 30),
(84, 'C84', 'Ursa Minor', 'Little Bear', 255.864, 'NQ3', 90, 10),
(85, 'C85', 'Vela', 'Sails', 499.649, 'SQ2', 30, 90),
(86, 'C86', 'Virgo', 'Virgin (Maiden)', 1294.428, 'SQ3', 80, 80),
(87, 'C87', 'Volans', 'Flying Fish', 141.354, 'SQ2', 15, 90),
(88, 'C88', 'Vulpecula', 'Fox', 268.165, 'NQ4', 90, 55);

-- Insert values into stars table
-- data source https://web.pa.msu.edu/people/horvatin/Astronomy_Facts/brightest_stars.html
INSERT INTO stars(
	id, star_id, common_name, astronomical_name, meaning,
    apparent_magnitude, absolute_magnitude, distance_light_years, constellation_id
)
VALUES
(1, 'S1', 'Sirius', 'Alpha Canis Majoris', 'Greek: scorching', -1.44, 1.45, 9, 'C14'),
(2, 'S2', 'Canopus', 'Alpha Carinae', 'Greek: pilot of the ship Argo', -0.62, -5.53, 313, 'C17'),
(3, 'S3', 'Arcturus', 'Alpha Bootis', 'Greek: guardian of the bear', -0.05, -0.31, 37, 'C9'),
(4, 'S4', 'Rigel Kentaurus', 'Alpha Centauri', 'Arabic: foot of the centaur', -0.01, 4.34, 4, 'C19'),
(5, 'S5', 'Vega', 'Alpha Lyrae', 'Arabic: eagle or vulture', 0.03, 0.58, 25, 'C52'),
(6, 'S6', 'Capella', 'Alpha Aurigae', 'Latin: little she-goat', 0.08, -0.48, 42, 'C8'),
(7, 'S7', 'Rigel', 'Beta Orionis', 'Arabic: foot', 0.18, -6.69, 773, 'C60'),
(8, 'S8', 'Procyon', 'Alpha Canis Minoris', 'Greek: before the dog', 0.4, 2.68, 11, 'C15'),
(9, 'S9', 'Betelgeuse', 'Alpha Orionis', 'Arabic: armpit of the great one', 0.45, -5.14, 522, 'C60'),
(10, 'S10', 'Achernar', 'Alpha Eridani', "Arabic: river's end", 0.45, -2.77, 144, 'C36'),
(11, 'S11', 'Hadar (Agena)', 'Beta Centauri', 'Arabic: ground (Latin: knee)', 0.61, -5.42, 526, 'C19'),
(12, 'S12', 'Altair', 'Alpha Aquilae', 'Arabic: the eagle', 0.76, 2.2, 17, 'C5'),
(13, 'S13', 'Acrux', 'Alpha Crucis', 'Greek: comb. of alpha crux', 0.77, -4.19, 321, 'C30'),
(14, 'S14', 'Aldebaran', 'Alpha Tauri', 'Arabic: the follower', 0.87, -0.63, 65, 'C78'),
(15, 'S15', 'Spica', 'Alpha Virginis', 'Latin: ear of wheat', 0.98, -3.55, 262, 'C86'),
(16, 'S16', 'Antares', 'Alpha Scorpii', 'Greek: rival of Mars', 1.06, -5.28, 604, 'C73'),
(17, 'S17', 'Pollux', 'Beta Geminorum', 'Greek: immortal Gemini twin brother', 1.16, 1.09, 34, 'C38'),
(18, 'S18', 'Formalhaut', 'Alpha Piscis Austrini', 'Arabic: the mouth of the fish', 1.17, 1.74, 25, 'C67'),
(19, 'S19', 'Deneb', 'Alpha Cygni', 'Arabic: tail', 1.25, -8.73, 1467, 'C31'),
(20, 'S20', 'Mimosa', 'Beta Crucis', 'Latin: actor', 1.25, -3.92, 352, 'C30'),
(21, 'S21', 'Regulus', 'Alpha Leonis', 'Greek: little king', 1.36, -0.52, 77, 'C46'),
(22, 'S22', 'Adhara', 'Epsilon Canis Majoris', 'Arabic: the virgins', 1.5, -4.1, 431, 'C14'),
(23, 'S23', 'Castor', 'Alpha Geminorum', 'Greek: mortal Gemini twin brother', 1.58, 0.59, 52, 'C38'),
(24, 'S24', 'Gacrux', 'Gamma Crucis', 'Greek: comb. of gamma and crux', 1.59, -0.56, 88, 'C30'),
(25, 'S25', 'Shaula', 'Lambda Scorpii', 'Arabic: stinger', 1.62, -5.05, 359, 'C73'),
(26, 'S26', 'Bellatrix', 'Gamma Orionis', 'Greek: an Amazon warrior', 1.64, -2.72, 243, 'C60'),
(27, 'S27', 'Alnath', 'Beta Tauri', 'Arabic: the butting one', 1.65, -1.37, 131, 'C78'),
(28, 'S28', 'Miaplacidus', 'Beta Carinae', 'Arabic/Latin: peaceful waters', 1.67, -0.99, 111, 'C17'),
(29, 'S29', 'Alnilam', 'Epsilon Orionis', 'Arabic: string of pearls', 1.69, -6.38, 1342, 'C60'),
(30, 'S30', 'Alnair', 'Alpha Gruis', 'Arabic: the bright one', 1.73, -0.73, 101, 'C39'),
(31, 'S31', 'Alnitak', 'Zeta Orionis', 'Arabic: the girdle', 1.74, -5.26, 817, 'C60'),
(32, 'S32', 'Regor', 'Gamma Velorum', 'unknown', 1.75, -5.31, 840, 'C85'),
(33, 'S33', 'Alioth', 'Epsilon Ursae Majoris', 'Arabic: the bull', 1.76, -0.21, 81, 'C83'),
(34, 'S34', 'Kaus Australis', 'Epsilon Sagittarii', 'Arabic/Latin: southern part of the bow', 1.79, -1.44, 145, 'C72'),
(35, 'S35', 'Mirphak', 'Alpha Persei', 'Arabic: elbow', 1.79, -4.5, 592, 'C63'),
(36, 'S36', 'Dubhe', 'Alpha Ursae Majoris', 'Arabic: bear', 1.81, -1.08, 124, 'C83'),
(37, 'S37', 'Wezen', 'Delta Canis Majoris', 'Arabic: weight', 1.83, -6.87, 1791, 'C14'),
(38, 'S38', 'Alkaid', 'Eta Ursae Majoris', 'Arabic: chief of the mourners', 1.85, -0.6, 101, 'C83'),
(39, 'S39', 'Sargas', 'Theta Scorpii', 'Sumerian: scorpion', 1.86, -2.75, 272, 'C73'),
(40, 'S40', 'Avior', 'Epsilon Carinae', 'unknown', 1.86, -4.58, 632, 'C17'),
(41, 'S41', 'Menkalinan', 'Beta Aurigae', 'Arabic: shoulder of the rein-holder', 1.9, -0.1, 82, 'C8'),
(42, 'S42', 'Atria', 'Alpha Trianguli Australis', 'Greek/English: combination of alpha and triangle', 1.91, -3.62, 415, 'C81'),
(43, 'S43', 'Delta Velorum', 'Delta Velorum', 'Bayer designation*', 1.93, -0.01, 80, 'C85'),
(44, 'S44', 'Alhena', 'Gamma Geminorum', "Arabic: the mark on the right side of a camel's neck", 1.93, -0.6, 105, 'C38'),
(45, 'S45', 'Peacock', 'Alpha Pavonis', 'English: Peacock', 1.94, -1.81, 183, 'C61'),
(46, 'S46', 'Polaris', 'Alpha Ursae Minoris', 'Latin: pole star', 1.97, -3.64, 431, 'C84'),
(47, 'S47', 'Mirzam', 'Beta Canis Majoris', 'Arabic: herald', 1.98, -3.95, 499, 'C14'),
(48, 'S48', 'Alphard', 'Alpha Hydrae', 'Arabic: the solitary one', 1.99, -1.69, 177, 'C42'),
(49, 'S49', 'Algieba', 'Gamma Leonis', 'Arabic: the forehead', 2.01, -0.92, 126, 'C46'),
(50, 'S50', 'Hamal', 'Alpha Arietis', 'Arabic: lamb', 2.01, 0.48, 66, 'C7'),
(51, 'S51', 'Deneb Kaitos', 'Beta Ceti', 'Arabic/Greek: tail of the sea monster', 2.04, -0.3, 96, 'C21'),
(52, 'S52', 'Nunki', 'Sigma Sagittarii', 'ancient Babylonian name', 2.05, -2.14, 224, 'C72'),
(53, 'S53', 'Merkent', 'Theta Centauri', 'Arabic: in the shoulder of the centaur', 2.06, 0.7, 61, 'C19'),
(54, 'S54', 'Saiph', 'Kappa Orionis', 'Arabic: sword', 2.07, -4.65, 815, 'C60'),
(55, 'S55', 'Alpheratz', 'Alpha Andromedae', "Arabic: horse's shoulder", 2.07, -0.3, 97, 'C1'),
(56, 'S56', 'Beta Gruis', 'Beta Gruis', 'Bayer designation*', 2.07, -1.52, 170, 'C39'),
(57, 'S57', 'Mirach', 'Beta Andromedae', 'Arabic: girdle', 2.07, -1.86, 199, 'C1'),
(58, 'S58', 'Kochab', 'Beta Ursae Minoris', 'Arabic: unknown meaning', 2.07, -0.87, 126, 'C84'),
(59, 'S59', 'Rasalhague', 'Alpha Ophiuchi', 'Arabic: head of the serpent-charmer', 2.08, 1.3, 47, 'C59'),
(60, 'S60', 'Algol', 'Beta Persei', "Arabic: the demon's head", 2.09, -0.18, 93, 'C63'),
(61, 'S61', 'Almaak', 'Gamma Andromedae', 'Arabic: type of small, predatory animal in Arabia', 2.1, -3.08, 355, 'C1'),
(62, 'S62', 'Denebola', 'Beta Leonis', "Arabic: lion's tail", 2.14, 1.92, 36, 'C46'),
(63, 'S63', 'Cih', 'Gamma Cassiopeiae', 'Chinese: whip', 2.15, -4.22, 613, 'C18'),
(64, 'S64', 'Muhlifain', 'Gamma Centauri', 'Arabic: oath', 2.2, -0.81, 130, 'C19'),
(65, 'S65', 'Naos', 'Zeta Puppis', 'Greek: ship', 2.21, -5.95, 1399, 'C68'),
(66, 'S66', 'Aspidiske', 'Iota Carinae', "Arabic: an ornament on a ship's stern", 2.21, -4.42, 694, 'C17'),
(67, 'S67', 'Alphecca (Gemma)', 'Alpha Coronae Borealis', 'Arabic: bright one of the dish (Latin: gem)', 2.22, 0.42, 75, 'C27'),
(68, 'S68', 'Suhail', 'Lambda Velorum', 'Arabic: an honorific title of respect', 2.23, -3.99, 573, 'C85'),
(69, 'S69', 'Sadir', 'Gamma Cygni', 'Arabic: a birds breast', 2.23, -6.12, 522, 'C31'),
(70, 'S70', 'Mizar', 'Zeta Ursae Majoris', 'Arabic: groin', 2.23, 0.33, 78, 'C83'),
(71, 'S71', 'Schedar', 'Alpha Cassiopeiae', 'Arabic: beast', 2.24, -1.99, 228, 'C18'),
(72, 'S72', 'Eltanin', 'Gamma Draconis', "Arabic: the dragon's head", 2.24, -1.04, 148, 'C34'),
(73, 'S73', 'Mintaka', 'Delta Orionis', 'Arabic: belt', 2.25, -4.99, 916, 'C60'),
(74, 'S74', 'Caph', 'Beta Cassiopeiae', 'Arabic: hand', 2.28, 1.17, 54, 'C18'),
(75, 'S75', 'Dschubba', 'Delta Scorpii', 'Arabic: forehead', 2.29, -3.16, 522, 'C73'),
(76, 'S76', 'Hao', 'Epsilon Scorpii', 'Chinese: queen', 2.29, 0.78, 65, 'C73'),
(77, 'S77', 'Epsilon Centauri', 'Epsilon Centauri', 'Bayer designation*', 2.29, -3.02, 376, 'C19'),
(78, 'S78', 'Alpha Lupi', 'Alpha Lupi', 'Bayer designation*', 2.3, -3.83, 548, 'C50'),
(79, 'S79', 'Eta Centauri', 'Eta Centauri', 'Bayer designation*', 2.33, -2.55, 308, 'C19'),
(80, 'S80', 'Merak', 'Beta Ursae Majoris', 'Arabic: flank', 2.34, 0.41, 79, 'C83'),
(81, 'S81', 'Izar', 'Epsilon Bootis', 'Arabic: girdle', 2.35, -1.69, 210, 'C9'),
(82, 'S82', 'Enif', 'Epsilon Pegasi', 'Arabic: nose', 2.38, -4.19, 672, 'C62'),
(83, 'S83', 'Kappa Scorpii', 'Kappa Scorpii', 'Bayer designation*', 2.39, -3.38, 464, 'C73'),
(84, 'S84', 'Ankaa', 'Alpha Phoenicis', 'Arabic: name of a legendary bird', 2.4, 0.52, 77, 'C64'),
(85, 'S85', 'Phecda', 'Gamma Ursae Majoris', 'Arabic: thigh', 2.41, 0.36, 84, 'C83'),
(86, 'S86', 'Sabik', 'Eta Ophiuchi', 'Arabic: unknown meaning', 2.43, 0.37, 84, 'C59'),
(87, 'S87', 'Scheat', 'Beta Pegasi', 'Arabic: shin', 2.44, -1.49, 199, 'C62'),
(88, 'S88', 'Alderamin', 'Alpha Cephei', 'Arabic: the right arm', 2.45, 1.58, 49, 'C20'),
(89, 'S89', 'Aludra', 'Eta Canis Majoris', 'Arabic: virginity', 2.45, -7.51, 3196, 'C14'),
(90, 'S90', 'Kappa Velorum', 'Kappa Velorum', 'Bayer designation*', 2.47, -3.62, 539, 'C85'),
(91, 'S91', 'Aljanah', 'Epsilon Cygni', 'Arabic: wing', 2.48, 0.76, 72, 'C31'),
(92, 'S92', 'Markab', 'Alpha Pegasi', 'Arabic: saddle', 2.49, -0.67, 140, 'C62'),
(93, 'S93', 'Han', 'Zeta Ophiuchi', 'Chinese: an ancient feudal state in China', 2.54, -3.2, 458, 'C59'),
(94, 'S94', 'Menkar', 'Alpha Ceti', 'Arabic: nose', 2.54, -1.61, 220, 'C21'),
(95, 'S95', 'Alnair', 'Zeta Centauri', 'Arabic: the bright one', 2.55, -2.81, 384, 'C19'),
(96, 'S96', 'Graffias', 'Beta Scorpii', 'Arabic(?): claws', 2.56, -3.5, 530, 'C73'),
(97, 'S97', 'Zosma', 'Delta Leonis', 'Greek: girdle', 2.56, 1.32, 58, 'C46'),
(98, 'S98', 'Ma Wei', 'Delta Centauri', "Chinese: the horse's tail", 2.58, -2.84, 395, 'C19'),
(99, 'S99', 'Arneb', 'Alpha Leporis', 'Arabic: hare', 2.58, -5.4, 1283, 'C48'),
(100, 'S100', 'Gienah Ghurab', 'Gamma Corvi', 'Arabic: right wing of the raven', 2.58, -0.94, 165, 'C28'),
(101, 'S101', 'Sun', NULL, NULL, -26.74, 4.83, 0.000015813, NULL),
(102, 'S102', 'Proxima Centauri', 'Alpha Centauri C', 'Latin/Greek: the closest star of the Centaur', 11.13, 15.6, 4.24, 'C19'),
(103, 'S103', 'Sirius B', 'Alpha Canis Majoris B', 'Pup Star', 8.44, 11.3, 8.61, 'C14');

-- Insert values into galaxies
-- data source: https://littleastronomy.com/galaxy-names/
INSERT INTO galaxies(
	id, galaxy_id, galaxy_name, meaning, constellation_id
)
VALUES
(1, 'G1', 'Andromeda Galaxy', 'In mythology, Andromeda is the daughter of the kings of Ethiopia and is said to be more beautiful than the Nereids. She becomes queen of Greece when she marries Perseus.', 'C1'),
(2, 'G2', 'Antennae Galaxy', 'This is a dual galaxy. It gets its name because it is said to look like a pair of insect antennae.', 'C28'),
(3, 'G3', 'Backward Galaxy', 'It seems to rotate in the opposite direction to what it should according to its shape.', 'C19'),
(4, 'G4', 'Black Eye Galaxy', 'It looks like an eye with a dark stripe underneath', 'C25'),
(5, 'G5', 'Bode’s Galaxy', 'Named after the astronomer who discovered it, Johann Elert Bode', 'C83'),
(6, 'G6', 'Butterfly Galaxies', 'Binary galaxies. It looks like a pair of butterfly wings.', 'C86'),
(7, 'G7', 'Cartwheel Galaxy', 'It looks a bit like a cartwheel', 'C74'),
(8, 'G8', 'Centaurus A', 'Named because it’s located in the Centaurus constellation', 'C19'),
(9, 'G9', 'Cigar Galaxy', 'It is shaped like a cigar', 'C83'),
(10, 'G10', 'Circinus', 'Latin for compass. Named after the constellation of the same name.', 'C23'),
(11, 'G11', 'Coma Pinwheel Galaxy', 'It looks like a paper pinwheel', 'C25'),
(12, 'G12', 'Comet Galaxy', 'It’s unusually shaped like a comet', 'C74'),
(13, 'G13', 'Cosmos Redshift 7', 'It’s the brightest of the distant galaxies. It contains some of the oldest stars we know of.', 'C77'),
(14, 'G14', 'Eye of Sauron', 'Looks like the eye of Sauron, from Lord of the rings.', 'C13'),
(15, 'G15', 'Fireworks Galaxy', 'It is extremely bright and has lots of colors.', 'C31'),
(16, 'G16', 'Hockey stick galaxy', 'Looks like a hockey stick. It might be 3 galaxies.', 'C13'),
(17, 'G17', 'Hoag’s Galaxy', 'Named after its discoverer, Art Hoag', 'C76'),
(18, 'G18', 'Large Magellanic Cloud', 'Named after Ferdinand Magellan', 'C33'),
(19, 'G19', 'Lindsay-Shapley Ring', 'Ring galaxy, named after its discoverer Eric Lindsay', 'C87'),
(20, 'G20', 'Little Sombrero Galaxy', 'It looks like a sombrero, but it’s smaller than the Sombrero Galaxy', 'C62'),
(21, 'G21', 'Malin 1', 'Named after its discoverer, David Malin', 'C25'),
(22, 'G22', 'Medusa Merger', 'Named after the snakes in the Greek myth of Medusa', 'C83'),
(23, 'G23', 'Sculptor Dwarf Galaxy', 'Named because it’s located in the Sculptor constellation', 'C74'),
(24, 'G24', 'Mice Galaxies', 'Two galaxies with long tails that look like a mouse', 'C25'),
(25, 'G25', 'Small Magellanic Cloud', 'Named after Ferdinand Magellan', 'C82'),
(26, 'G26', 'Mayall’s Object', 'Named after its discoverer, Nicholas Mayall', 'C83'),
(27, 'G27', 'Milky Way', 'Our own galaxy. It is said to look like a band of light', NULL),
(28, 'G28', 'Needle Galaxy', 'Named because of its thin appearance', 'C25'),
(29, 'G29', 'Wolf-Lundmark-Melotte', 'Named after the astronomers that co-discovered it', 'C21'),
(30, 'G30', 'Pinwheel Galaxy', 'It looks like a paper pinwheel', 'C83'),
(31, 'G31', 'Sculptor Galaxy', 'Named because it’s located in the Sculptor constellation', 'C74'),
(32, 'G32', 'Sombrero Galaxy', 'Looks like a sombrero', 'C86'),
(33, 'G33', 'Southern Pinwheel Galaxy', 'Named because it looks similar to the Pinwheel Galaxy', 'C42'),
(34, 'G34', 'Sunflower Galaxy', 'Named because it looks a bit a sunflower', 'C13'),
(35, 'G35', 'Tadpole Galaxy', 'It has a long tail, like a tadpole', 'C34'),
(36, 'G36', 'Triangulum Galaxy', 'It’s located in the Triangulum Constellation', 'C80'),
(37, 'G37', 'Whirlpool Galaxy', 'Named because it looks like a whirlpool', 'C13');

-- Insert values into intrumentation
INSERT INTO instrumentation(
	instrument_id, instrument
)
VALUES
(1, 'Naked Eye'),
(2, 'Amateur Telescope'),
(3, 'Observatory Telescope'),
(4, 'Space Telescope');

-- Insert valid values into observability using the stored procedure
-- data source for observability was mostly Wikipedia and general google search whether certain planets/moons/stars/constellations/galaxies
-- are visible with naked eye or with certain instruments
CALL InsertObservabilityObject (1, 'M1', 'moon');
CALL InsertObservabilityObject (1, 'P6', 'planet');
CALL InsertObservabilityObject (1, 'P5', 'planet');
CALL InsertObservabilityObject (1, 'S46', 'star');
CALL InsertObservabilityObject (1, 'S1', 'star');
CALL InsertObservabilityObject (1, 'S19', 'star');
CALL InsertObservabilityObject (1, 'G27', 'galaxy');
CALL InsertObservabilityObject (1, 'G1', 'galaxy');
CALL InsertObservabilityObject (1, 'G4', 'galaxy');
CALL InsertObservabilityObject (1, 'G32', 'galaxy');
CALL InsertObservabilityObject (1, 'C31', 'constellation');
CALL InsertObservabilityObject (1, 'C38', 'constellation');
CALL InsertObservabilityObject (1, 'C52', 'constellation');
CALL InsertObservabilityObject (1, 'C83', 'constellation');
CALL InsertObservabilityObject (2, 'M104', 'moon');
CALL InsertObservabilityObject (2, 'M6', 'moon');
CALL InsertObservabilityObject (2, 'M103', 'moon');
CALL InsertObservabilityObject (2, 'M7', 'moon');
CALL InsertObservabilityObject (2, 'M4', 'moon');
CALL InsertObservabilityObject (2, 'S46', 'star');
CALL InsertObservabilityObject (2, 'G1', 'galaxy');
CALL InsertObservabilityObject (2, 'G4', 'galaxy');
CALL InsertObservabilityObject (3, 'C55', 'constellation');
CALL InsertObservabilityObject (3, 'S46', 'star');
CALL InsertObservabilityObject (3, 'G29', 'galaxy');
CALL InsertObservabilityObject (3, 'S103', 'star');
CALL InsertObservabilityObject (3, 'M65', 'moon');
CALL InsertObservabilityObject (4, 'G29', 'galaxy');
CALL InsertObservabilityObject (4, 'G13', 'galaxy');
CALL InsertObservabilityObject (4, 'S46', 'star');
CALL InsertObservabilityObject (4, 'M285', 'moon');
CALL InsertObservabilityObject (4, 'S102', 'star');

-- for better user experience, whitespaces, upper case in object type and lower case in object id in the procedure call are ignored 
-- the values are inserted consistently (all lower case for object_type, and upper case for object_id) 
-- for better readability of the query outputs
CALL InsertObservabilityObject(1, 'P1   ', '  planet  ');
CALL InsertObservabilityObject (1, 'P2', 'PLANET');
CALL InsertObservabilityObject (1, 'p4', 'Planet');

-- Attempt to insert invalid values into observability (e.g. P1 is a planet (Mercury), not a moon)
-- uncomment the below to demonstrate invalid attempt
-- CALL InsertObservabilityObject (1, 'P1', 'moon');

-- triggers to update observability table in case a row from planets, moons, stars, constellations or galaxies is deleted
-- trigger for planet table
DELIMITER //
CREATE TRIGGER after_delete_planet
AFTER DELETE ON planets
FOR EACH ROW
BEGIN
	DELETE FROM observability WHERE object_id = OLD.planet_id;
END; //
DELIMITER;

-- trigger for moons table
DELIMITER //
CREATE TRIGGER after_delete_moon
AFTER DELETE ON moons
FOR EACH ROW
BEGIN
	DELETE FROM observability WHERE object_id = OLD.moon_id;
END; //
DELIMITER;

-- trigger for stars table
DELIMITER //
CREATE TRIGGER after_delete_star
AFTER DELETE ON stars
FOR EACH ROW
BEGIN
	DELETE FROM observability WHERE object_id = OLD.star_id;
END; //
DELIMITER;

-- trigger for constellations table
DELIMITER //
CREATE TRIGGER after_delete_constellation
AFTER DELETE ON constellations
FOR EACH ROW
BEGIN
	DELETE FROM observability WHERE object_id = OLD.constellation_id;
END; //
DELIMITER;

-- trigger for galaxies table
DELIMITER //
CREATE TRIGGER after_delete_galaxy
AFTER DELETE ON galaxies
FOR EACH ROW
BEGIN
	DELETE FROM observability WHERE object_id = OLD.galaxy_id;
END; //
DELIMITER;

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

-- Stored function calculating average planet radius based on planet type
DELIMITER //
CREATE FUNCTION avg_planet_radius_per_type (type_of_planet VARCHAR(50))
RETURNS FLOAT
READS SQL DATA
BEGIN
	DECLARE avg_radius FLOAT;
    
    SELECT AVG(radius_km) INTO avg_radius
    FROM planets
    WHERE planet_type = type_of_planet;
    
    RETURN avg_radius;
END; //    
DELIMITER ;
