USE [custom]
GO
/****** Object:  StoredProcedure [dbo].[CCECleanup]    Script Date: 03/02/2015 09:09:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/**
 * Method       : CCECleanup
 * Description  :   This SPROC accepts 3 arguments. First one is for the two-letter site code. 
					However, the user can pass in "XX" as a site code and that will tell the
					SPROC to find records for all of the site codes in the SiteInfo table. 
					The second parameter tells how far the SPROC should look back. 0 can be 
					passed in by default and that will tell the SPROC to look back 60 days
					for CCE objects. Alternatively, a value such as -120 could be passed in 
					and that will tell the SPROC to look back 120 days. Please note , the 
					dash is required in the expression. Lastly, the third parameter tells
					the SPROC to look for objects under a certain module id. This could be 
					set to 0 by default which shouldn't find any objects unless that number
					is somehow being used as a module ID.
 * Created      : 20141204 SSW 
**/
ALTER PROCEDURE [dbo].[CCECleanup]

	/** 
		Site Code parameter
		Accepts "XX" for all site codes 
		or a specific site code such as 
		"BD"
	**/
	@ACCESite VARCHAR(2),
	
	/** 
		Look back parameter
		Accepts 0, -120, -500, etc
		0 tells it to look back 60 days
		by default
	**/
	@ALookBack INT = 60,
	
	/** 
		Module ID parameter 
		Accepts integer values 
		setting 1 as argument means
		to look for objects under module ID 1 
	**/
	@AModuleID INT,
	
	/** 
		Debug parameter 
		Accepts interger value 1 or 0
		1 means enabled, 0 means disabled 
	**/
	@ADebug INT = 0
	
AS

BEGIN
  
	/** 
		Time stamp variable so -60 can be converted to 
		2014-10-24 09:24:23.753, for example 
	**/
	DECLARE @ATimeStamp DATETIME

	/** Converts -60,-120, etc to a datetime format **/
	SET @ATimeStamp = DATEADD(D, - ABS(@ALookBack), GETDATE())

	/* Prints out information when the Debug parameter is set to 1 */ 
	IF (@ADebug = 1)
	
		PRINT 'FINAL Parameter values:' + CHAR(13) + 
		'=================================' + CHAR(13) + 
		'@ACCESite: ' + @ACCESite + CHAR(13) + 
		'@ALookBack: ' + CONVERT(VARCHAR(10), @ALookback) + CHAR(13) + 
		'@ATimeStamp: ' + CONVERT(VARCHAR(20), @ATimeStamp) + CHAR(13) + 
		'@AModuleID: ' + CONVERT(VARCHAR(10), @AModuleID) + CHAR(13) + CHAR(13)
		
	ELSE
	
		PRINT 'Debugging is turned off' + CHAR(13) + CHAR(13)
	
		PRINT 'CCE Objects Deleted' + CHAR(13) + 
		'===========================================' + CHAR(13) + 
		'Site' + SPACE(3) + 'GUID' + CHAR(13) + 
		'-------------------------------------------'

	SET NOCOUNT ON

	/** 
		Temp table for storing the site codes that should be used 
		for the select statement
	**/
	DECLARE @SiteCodesTable TABLE (sitecode VARCHAR(2))

	/** 
		Inserts all of the sitecodes found in the 
		web.dbo.siteinfo table if XX is passed in 
		an argument. Otherwise, just a single
		site code is inserted in
	**/
	IF (@ACCESite = 'XX')
		INSERT INTO @SiteCodesTable (sitecode)
		SELECT avis
		FROM web.dbo.siteinfo(NOLOCK)
	ELSE
		INSERT INTO @SiteCodesTable (sitecode)
		VALUES (@ACCESite)

	/** 
		This variable is for holding each of the site codes in the 
		cursor statement 
	**/
	DECLARE @ASite VARCHAR(2)

	DECLARE sitecodes CURSOR SCROLL FOR
	
	/** The cursor selects form this table to obtain the necessary site code value(s) **/
	SELECT *
	FROM @SiteCodesTable

	OPEN sitecodes

	/** The cursor fetches each of the sitecodes in the temporary 
		site code table and assigns the ASite var to the fetched 
		site code 
	**/
	FETCH FIRST FROM sitecodes INTO @ASite

	WHILE @@fetch_status = 0
	
	BEGIN
	
		/** Variable for holding the CCE Object GUID **/
		DECLARE @anObjectGUID VARCHAR(255)
		
		/** Variable for holding the counter increment value **/
		DECLARE @ACounter INT

		DECLARE deletecursor CURSOR SCROLL FOR
		
		/** The cursor selects from this table for all of the records that should be deleted **/
		SELECT cceobjectguid
		FROM cce.dbo.cce_status(NOLOCK)
		WHERE site = @ASite
			AND modified < @ATimeStamp
			AND module = @AModuleID
		
		SET @ACounter = 1

		OPEN deletecursor

		FETCH FIRST FROM deletecursor INTO @anObjectGUID

		WHILE @@fetch_status = 0
		
		BEGIN
		
			BEGIN TRY
			
				IF (@ADebug = 0)
				
				/* The below SELECT statement is for testing exception handeling */
				-- SELECT 1/0
				
				EXECUTE cce.dbo.CCE_DeleteObject 
				@anObjectGUID 
					
			END TRY

			BEGIN CATCH
				PRINT ('An error has occurred! #' + CONVERT(VARCHAR(16), ERROR_NUMBER()) + CHAR(13) + CHAR(10) + ERROR_MESSAGE())
			END CATCH


			/** Print statement for showing which records were deleted **/
			PRINT @ASite + SPACE(5) + @anObjectGUID
			
			PRINT ' '

			FETCH NEXT FROM deletecursor INTO @anObjectGUID

			SET @ACounter = @ACounter + 1
			
		END

		CLOSE deletecursor

		DEALLOCATE deletecursor /*** End of Delete cursor **/

		FETCH NEXT FROM sitecodes INTO @asite
		
	END

	/** End of While loop **/
	CLOSE sitecodes

	DEALLOCATE sitecodes /** End of Sitecodes cursor **/

	SET NOCOUNT OFF
	
END

PRINT '---'

