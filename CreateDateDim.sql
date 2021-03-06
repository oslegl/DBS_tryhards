
DELETE FROM [dbo].[DimDate]
/********************************************************************************************/
--Specify Start Date and End date here
--Value of Start Date Must be Less than Your End Date 

DECLARE @StartDate DATETIME = '2016-01-01' --Starting value of Date Range
DECLARE @EndDate DATETIME = '2017-12-31' --End Value of Date Range

--Temporary Variables To Hold the Values During Processing of Each Date of Year
DECLARE
	@DayOfWeekInMonth INT,
	@DayOfWeekInYear INT,
	@DayOfQuarter INT,
	@WeekOfMonth INT,
	@CurrentYear INT,
	@CurrentMonth INT,
	@CurrentQuarter INT

/*Table Data type to store the day of week count for the month and year*/
DECLARE @DayOfWeek TABLE (DOW INT, MonthCount INT, QuarterCount INT, YearCount INT)

INSERT INTO @DayOfWeek VALUES (1, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (2, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (3, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (4, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (5, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (6, 0, 0, 0)
INSERT INTO @DayOfWeek VALUES (7, 0, 0, 0)

--Extract and assign various parts of Values from Current Date to Variable

DECLARE @CurrentDate AS DATETIME = @StartDate
SET @CurrentMonth = DATEPART(MM, @CurrentDate)
SET @CurrentYear = DATEPART(YY, @CurrentDate)
SET @CurrentQuarter = DATEPART(QQ, @CurrentDate)

/********************************************************************************************/
--Proceed only if Start Date(Current date ) is less than End date you specified above

WHILE @CurrentDate < @EndDate
BEGIN
 
/*Begin day of week logic*/

         /*Check for Change in Month of the Current date if Month changed then 
          Change variable value*/
	IF @CurrentMonth != DATEPART(MM, @CurrentDate) 
	BEGIN
		UPDATE @DayOfWeek
		SET MonthCount = 0
		SET @CurrentMonth = DATEPART(MM, @CurrentDate)
	END

        /* Check for Change in Quarter of the Current date if Quarter changed then change 
         Variable value*/

	IF @CurrentQuarter != DATEPART(QQ, @CurrentDate)
	BEGIN
		UPDATE @DayOfWeek
		SET QuarterCount = 0
		SET @CurrentQuarter = DATEPART(QQ, @CurrentDate)
	END
       
        /* Check for Change in Year of the Current date if Year changed then change 
         Variable value*/


	IF @CurrentYear != DATEPART(YY, @CurrentDate)
	BEGIN
		UPDATE @DayOfWeek
		SET YearCount = 0
		SET @CurrentYear = DATEPART(YY, @CurrentDate)
	END
	
        -- Set values in table data type created above from variables 

	UPDATE @DayOfWeek
	SET 
		MonthCount = MonthCount + 1,
		QuarterCount = QuarterCount + 1,
		YearCount = YearCount + 1
	WHERE DOW = DATEPART(DW, @CurrentDate)

	SELECT
		@DayOfWeekInMonth = MonthCount,
		@DayOfQuarter = QuarterCount,
		@DayOfWeekInYear = YearCount
	FROM @DayOfWeek
	WHERE DOW = DATEPART(DW, @CurrentDate)
	
/*End day of week logic*/


/* Populate Your Dimension Table with values*/
	
	INSERT INTO [dbo].[DimDate]
	SELECT
		
		@CurrentDate AS Date,

		CASE
		
		WHEN (MONTH(@CurrentDate) >= 3 AND DAY(@CurrentDate) >= 1) AND (MONTH(@CurrentDate) <= 5 AND DAY(@CurrentDate) <= 31) THEN
			'Spring'
		WHEN (MONTH(@CurrentDate) >= 6 AND DAY(@CurrentDate) >= 1) AND (MONTH(@CurrentDate) <= 8 AND DAY(@CurrentDate) <= 31) THEN
			'Summer'
		WHEN (MONTH(@CurrentDate) >= 9 AND DAY(@CurrentDate) >= 1) AND (MONTH(@CurrentDate) <= 11 AND DAY(@CurrentDate) <= 31) THEN
			'Autumn'
		WHEN (MONTH(@CurrentDate) >= 12 AND DAY(@CurrentDate) >= 1) AND (MONTH(@CurrentDate) <= 2 AND DAY(@CurrentDate) <= 28) THEN
			'Winter'
		ELSE
			'Winter'
		END AS Season,

		
	
		CONVERT (char(10),@CurrentDate,104) as FormattedDate,
		DATEPART(DD, @CurrentDate) AS DayOfMonth,
		
		DATENAME(DW, @CurrentDate) AS DayName,
				
		@DayOfWeekInMonth AS DayOfWeekInMonth,@DayOfWeekInYear AS DayOfWeekInYear,@DayOfQuarter AS DayOfQuarter,DATEPART(DY, @CurrentDate) AS DayOfYear,
		
		DATEPART(WW, @CurrentDate) + 1 - DATEPART(WW, CONVERT(VARCHAR,DATEPART(MM, @CurrentDate)) + '/1/' + CONVERT(VARCHAR, DATEPART(YY, @CurrentDate))) AS WeekOfMonth,(DATEDIFF(DD, DATEADD(QQ, DATEDIFF(QQ, 0, @CurrentDate), 0), @CurrentDate) / 7) + 1 AS WeekOfQuarter,DATEPART(WW, @CurrentDate) AS WeekOfYear,
		
		DATEPART(MM, @CurrentDate) AS Month,
		
		DATENAME(MM, @CurrentDate) AS MonthName,
		
		CASE
			WHEN DATEPART(MM, @CurrentDate) IN (1, 4, 7, 10) THEN 1
			WHEN DATEPART(MM, @CurrentDate) IN (2, 5, 8, 11) THEN 2
			WHEN DATEPART(MM, @CurrentDate) IN (3, 6, 9, 12) THEN 3
			END AS MonthOfQuarter,
		
		DATEPART(QQ, @CurrentDate) AS Quarter,
		
		CASE DATEPART(QQ, @CurrentDate)
			WHEN 1 THEN 'First'
			WHEN 2 THEN 'Second'
			WHEN 3 THEN 'Third'
			WHEN 4 THEN 'Fourth'
		
			END AS QuarterName,
		
		DATEPART(YEAR, @CurrentDate) AS Year,
	
		
				CASE DATEPART(DW, @CurrentDate)
			WHEN 1 THEN 'No'
			WHEN 2 THEN 'Yes'
			WHEN 3 THEN 'Yes'
			WHEN 4 THEN 'Yes'
			WHEN 5 THEN 'Yes'
			WHEN 6 THEN 'Yes'
			WHEN 7 THEN 'No'
			end AS IsWeekday
	
	SET @CurrentDate = DATEADD(DD, 1, @CurrentDate)
END


SELECT * FROM [dbo].[DimDate]