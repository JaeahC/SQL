############################################## Team 6 Group Project ###############################################################
# calling the data from H_Accounting database
USE H_Accounting;

############################################## BALANCE SHEET STATEMENT ############################################################
# Change the procedure name

# DROP PROCEDURE IF EXISTS `jaechoi2020_balance`;

# Changing delimiter 
DELIMITER $$
# Creating procedure to import data into final tables
	CREATE PROCEDURE `jaechoi2020_balance`(varCalendarYear YEAR)
	BEGIN
	
    # Balance Sheet (B/S) statements
	SELECT ss.statement_section_code AS STATEMENT_CODE, ss.statement_section AS DISCRIPTION,
		   FORMAT(((IFNULL(SUM(debit),0)) - IFNULL(SUM(credit),0)),2) AS BALANCE 

		FROM journal_entry_line_item AS jel
			INNER JOIN `account` AS acc ON jel.account_id = acc.account_id 
			INNER JOIN statement_section AS ss ON acc.balance_sheet_section_id = ss.statement_section_id  
			INNER JOIN journal_entry AS je ON je.journal_entry_id = jel.journal_entry_id
				WHERE is_balance_sheet_section = 1
					# AND je.closing_type <> 1 
                    AND je.cancelled <> 1
                    AND je.debit_credit_balanced = 1
                    AND YEAR(entry_date) <= varCalendarYear
			GROUP BY STATEMENT_CODE, DISCRIPTION, ss.statement_section_order
			ORDER BY ss.statement_section_order
			;# getting trial balance with statement_section per year FOR BALANCE SHEET		
    
	END $$

DELIMITER ;

# QUERY TO GET BALANCE SHEET UP TO A YEAR
CALL `jaechoi2020_balance`(2017); #2020 WILL NEED INCOME STATEMENT

############################################## INCOME STATEMENT ############################################################
# Dropping procedure

# DROP PROCEDURE IF EXISTS `jaechoi2020_income_stament`;

DELIMITER $$
# Creating procedure to import data into final tables
	CREATE PROCEDURE `jaechoi2020_income_stament`(varCalendarYear YEAR)
	BEGIN
	# Profit Loss (P/L) statement
	SELECT *
    FROM (SELECT statement_section_order AS `ORDER`,statement_section_code AS STATEMENT_CODE, statement_section as DISCRIPTION,
				 FORMAT(((IFNULL(SUM(debit),0)) - IFNULL(SUM(credit),0))*-1,2) AS THIS_YEAR
			FROM journal_entry_line_item
			INNER JOIN `account` ON journal_entry_line_item.account_id = `account`.account_id 
			INNER JOIN statement_section ON `account`.profit_loss_section_id = statement_section.statement_section_id  
			INNER JOIN journal_entry ON journal_entry.journal_entry_id = journal_entry_line_item.journal_entry_id
			WHERE profit_loss_section_id <> 0
				AND closing_type <> 1 
				AND cancelled = 0
				AND YEAR(entry_date) = varCalendarYear
			GROUP BY STATEMENT_CODE, DISCRIPTION, `ORDER`
	
    UNION 
    
		  SELECT "99" , "TP", "NET PROFIT", FORMAT(((IFNULL(SUM(debit),0)) - IFNULL(SUM(credit),0))*-1,2) AS THIS_YEAR
			FROM journal_entry_line_item
			INNER JOIN `account` ON journal_entry_line_item.account_id = `account`.account_id 
			INNER JOIN statement_section ON `account`.profit_loss_section_id = statement_section.statement_section_id  
			INNER JOIN journal_entry ON journal_entry.journal_entry_id = journal_entry_line_item.journal_entry_id
			WHERE profit_loss_section_id <> 0
				AND closing_type <> 1 
				AND cancelled = 0
				AND YEAR(entry_date) = varCalendarYear
				ORDER BY `ORDER`, DISCRIPTION
			) AS consulted_year 
    
    LEFT JOIN (SELECT STATEMENT_CODE, DISCRIPTION, PREV_YEAR
				FROM (SELECT statement_section_order AS `ORDER`,statement_section_code AS STATEMENT_CODE, statement_section as DISCRIPTION,
							 FORMAT(((IFNULL(SUM(debit),0)) - IFNULL(SUM(credit),0))*-1,2) AS PREV_YEAR
						FROM journal_entry_line_item
						INNER JOIN `account` ON journal_entry_line_item.account_id = `account`.account_id 
						INNER JOIN statement_section ON `account`.profit_loss_section_id = statement_section.statement_section_id  
						INNER JOIN journal_entry ON journal_entry.journal_entry_id = journal_entry_line_item.journal_entry_id
						WHERE profit_loss_section_id <> 0
							AND closing_type <> 1 
							AND cancelled = 0
							AND YEAR(entry_date) = varCalendarYear-1
						GROUP BY STATEMENT_CODE, DISCRIPTION, `ORDER`
						ORDER BY `ORDER`, DISCRIPTION
					) AS last_year
        UNION
    
				SELECT "TP", "NET PROFIT", FORMAT(((IFNULL(SUM(debit),0)) - IFNULL(SUM(credit),0))*-1,2) AS THIS_YEAR
				 FROM journal_entry_line_item
				INNER JOIN `account` ON journal_entry_line_item.account_id = `account`.account_id 
				INNER JOIN statement_section ON `account`.profit_loss_section_id = statement_section.statement_section_id  
				INNER JOIN journal_entry ON journal_entry.journal_entry_id = journal_entry_line_item.journal_entry_id
				WHERE profit_loss_section_id <> 0
					AND closing_type <> 1 
					AND cancelled = 0
					AND YEAR(entry_date) = varCalendarYear-1
        
			) AS last_year_2 ON consulted_year.STATEMENT_CODE = last_year_2.STATEMENT_CODE
        
        UNION
        
        SELECT *
		  FROM (SELECT statement_section_order AS `ORDER`,statement_section_code AS STATEMENT_CODE, statement_section as DISCRIPTION,
						FORMAT(((IFNULL(SUM(debit),0)) - IFNULL(SUM(credit),0))*-1,2) AS THIS_YEAR
				FROM journal_entry_line_item
				INNER JOIN `account` ON journal_entry_line_item.account_id = `account`.account_id 
				INNER JOIN statement_section ON `account`.profit_loss_section_id = statement_section.statement_section_id  
				INNER JOIN journal_entry ON journal_entry.journal_entry_id = journal_entry_line_item.journal_entry_id
				WHERE profit_loss_section_id <> 0
					AND closing_type <> 1 
					AND cancelled = 0
					AND YEAR(entry_date) = varCalendarYear
				GROUP BY STATEMENT_CODE, DISCRIPTION, `ORDER`
				ORDER BY `ORDER`, DISCRIPTION
				) AS consulted_year 
	
    RIGHT JOIN (SELECT STATEMENT_CODE, DISCRIPTION, PREV_YEAR
				FROM (SELECT statement_section_order AS `ORDER`,statement_section_code AS STATEMENT_CODE, statement_section as DISCRIPTION,
							 FORMAT(((IFNULL(SUM(debit),0)) - IFNULL(SUM(credit),0))*-1,2) AS PREV_YEAR
						FROM journal_entry_line_item
						INNER JOIN `account` ON journal_entry_line_item.account_id = `account`.account_id 
						INNER JOIN statement_section ON `account`.profit_loss_section_id = statement_section.statement_section_id  
						INNER JOIN journal_entry ON journal_entry.journal_entry_id = journal_entry_line_item.journal_entry_id
						WHERE profit_loss_section_id <> 0
							AND closing_type <> 1 
							AND cancelled = 0
							AND YEAR(entry_date) = varCalendarYear-1
						GROUP BY STATEMENT_CODE, DISCRIPTION, `ORDER`
						ORDER BY `ORDER`, DISCRIPTION
					 ) AS last_year
				) AS last_year_2 ON consulted_year.STATEMENT_CODE = last_year_2.STATEMENT_CODE 
        
		;# getting income statement with statement_section from last two years FOR INCOME STATEMENT
	END $$
DELIMITER ;

# QUERY TO GET INCOME STATEMENT UP TO A YEAR
CALL `jaechoi2020_income_stament`(2017); # 2019 THEY DIDNT HAVE ANY RESULTS

############ Extra work using If statement ############
############ Idea of solve the team project in different approach ############

# DROP PROCEDURE `jaeachoi2020_if_statement`;

DELIMITER $$
CREATE PROCEDURE `jaeachoi2020_if_statement`(vartype VARCHAR(10),varsscode VARCHAR(10), varentry_year YEAR)
BEGIN
    IF vartype = 'B/S' THEN
		IF varsscode = 'ALL' THEN
			SELECT ss.statement_section AS Label_Balance_Sheet, FORMAT(SUM(jeli.debit),2) AS Amount_of_Debit, FORMAT(SUM(jeli.credit),2) AS Amount_of_Credit, YEAR(je.entry_date) AS Entry_Year
			FROM account AS a
			LEFT OUTER JOIN journal_entry_line_item AS jeli ON a.account_id = jeli.account_id
			LEFT OUTER JOIN journal_entry AS je ON jeli.journal_entry_id = je.journal_entry_id
			LEFT OUTER JOIN journal_type AS jt ON je.journal_type_id = jt.journal_type_id
			LEFT OUTER JOIN statement_section AS ss ON a.balance_sheet_section_id = ss.statement_section_id
			WHERE a.account_id <> 0
				AND ss.statement_section_id <> 0
				AND je.closing_type <> 1
				AND je.cancelled <> 1
                AND YEAR(je.entry_date) = varentry_year
			GROUP BY Label_Balance_Sheet, Entry_Year
			ORDER BY Entry_Year, Label_Balance_Sheet;
		ELSE
			SELECT ss.statement_section AS Label_Balance_Sheet, FORMAT(SUM(jeli.debit),2) AS Amount_of_Debit, FORMAT(SUM(jeli.credit),2) AS Amount_of_Credit, YEAR(je.entry_date) AS Entry_Year
			FROM account AS a
			LEFT OUTER JOIN journal_entry_line_item AS jeli ON a.account_id = jeli.account_id
			LEFT OUTER JOIN journal_entry AS je ON jeli.journal_entry_id = je.journal_entry_id
			LEFT OUTER JOIN journal_type AS jt ON je.journal_type_id = jt.journal_type_id
			LEFT OUTER JOIN statement_section AS ss ON a.balance_sheet_section_id = ss.statement_section_id
			WHERE a.account_id <> 0
				AND ss.statement_section_id <> 0
				AND je.closing_type <> 1
				AND je.cancelled <> 1
                AND ss.statement_section_code = varsscode
                AND YEAR(je.entry_date) = varentry_year
			GROUP BY Label_Balance_Sheet, Entry_Year
			ORDER BY Entry_Year, Label_Balance_Sheet;
		END IF;
    ELSEIF vartype = 'P&L' THEN
		IF varsscode = 'ALL' THEN
			SELECT ss.statement_section AS Label_Profit_Loss, FORMAT(SUM(jeli.debit),2) AS Amount_of_Debit, FORMAT(SUM(jeli.credit),2) AS Amount_of_Credit, YEAR(je.entry_date) AS Entry_Year
				FROM account AS a
				LEFT OUTER JOIN journal_entry_line_item AS jeli ON a.account_id = jeli.account_id
				LEFT OUTER JOIN journal_entry AS je ON jeli.journal_entry_id = je.journal_entry_id
				LEFT OUTER JOIN journal_type AS jt ON je.journal_type_id = jt.journal_type_id
				LEFT OUTER JOIN statement_section AS ss ON a.profit_loss_section_id = ss.statement_section_id
				WHERE a.account_id <> 0
					AND ss.statement_section_id <> 0
					AND je.closing_type <> 1
					AND je.cancelled <> 1
                    AND YEAR(je.entry_date) = varentry_year
				GROUP BY Label_Profit_Loss, Entry_Year
				ORDER BY Entry_Year, Label_Profit_Loss;
			ELSE
				SELECT ss.statement_section AS Label_Profit_Loss, FORMAT(SUM(jeli.debit),2) AS Amount_of_Debit, FORMAT(SUM(jeli.credit),2) AS Amount_of_Credit, YEAR(je.entry_date) AS Entry_Year
				FROM account AS a
				LEFT OUTER JOIN journal_entry_line_item AS jeli ON a.account_id = jeli.account_id
				LEFT OUTER JOIN journal_entry AS je ON jeli.journal_entry_id = je.journal_entry_id
				LEFT OUTER JOIN journal_type AS jt ON je.journal_type_id = jt.journal_type_id
				LEFT OUTER JOIN statement_section AS ss ON a.profit_loss_section_id = ss.statement_section_id
				WHERE a.account_id <> 0
					AND ss.statement_section_id <> 0
					AND je.closing_type <> 1
					AND je.cancelled <> 1
                    AND ss.statement_section_code = varsscode
                    AND YEAR(je.entry_date) = varentry_year
				GROUP BY Label_Profit_Loss, Entry_Year
				ORDER BY Entry_Year, Label_Profit_Loss;
			END IF;
    END IF;

END $$
DELIMITER ;

	
###########		1st input variable is to choose the table
###########		B/S —— Balance Sheet
###########		P&L —— Profit and Loss

SELECT statement_section, statement_section_code from statement_section;
## use statement_section_code as 2nd input variable ##
## input 'ALL' to show all statement_section ##
SELECT DISTINCT YEAR(entry_date) FROM journal_entry;
## 2014-2018 are recommended as the 3rd input variable ##

CALL  jaeachoi2020_if_statement('P&L','ALL',2018);
