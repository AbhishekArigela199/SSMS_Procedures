-- Get employee names who have the same salary and belong to the same department

-- View all employees
SELECT * FROM Employee;

-----------------------------------------------------
-- Method 1: Using INNER JOIN to find employees with same salary and department
-----------------------------------------------------
SELECT 
    E.ID, E.Name, E.Department, E.Salary, 
    E1.ID AS Matching_ID, E1.Name AS Matching_Name
FROM Employee E (NOLOCK)
INNER JOIN Employee E1 (NOLOCK) 
    ON E.Department = E1.Department 
    AND E.Salary = E1.Salary 
    AND E.ID <> E1.ID
ORDER BY E1.Salary ASC;

-----------------------------------------------------
-- Method 2: Using CTE and GROUP BY to identify salaries appearing more than once
-----------------------------------------------------
WITH CTE AS (
    SELECT 
        Salary, 
        Department, 
        COUNT(*) AS SameSalaryCount
    FROM Employee (NOLOCK)
    GROUP BY Salary, Department
    HAVING COUNT(*) > 1
)
SELECT 
    E.ID, E.Name, E.Department, E.Salary 
FROM Employee E
INNER JOIN CTE C 
    ON E.Salary = C.Salary 
    AND E.Department = C.Department;

-----------------------------------------------------
-- Method 3: Using COUNT() OVER() to count occurrences of salary per department
-----------------------------------------------------
SELECT ID, Name, Salary, Department 
FROM (
    SELECT 
        *, 
        COUNT(*) OVER (PARTITION BY Department, Salary ORDER BY Salary) AS SalaryCount
    FROM Employee
) A
WHERE SalaryCount > 1;
----------------------------------------------------
-- Create Employee table
CREATE TABLE Employee2 (
    EmpID INT PRIMARY KEY,
    DeptID INT,
    Salary DECIMAL(10,2)
);

-- Insert sample data
INSERT INTO Employee2 (EmpID, DeptID, Salary) VALUES
(1, 101, 50000),
(2, 101, 60000),
(3, 101, 70000),
(4, 102, 55000),
(5, 102, 65000),
(6, 102, 75000),
(7, 103, 80000),
(8, 103, 90000),
(9, 103, 100000);

Select DeptID, Salary From (
Select DeptID,salary, Dense_rank() Over(Partition by DeptID order by salary desc) as rank1 From Employee2 (nolock)
group by DeptID, Salary
) AS T
Where rank1 = 3;

With CTE AS
(
Select DeptID, Salary, Dense_Rank() Over(Partition By DeptID Order By Salary Desc) r1 From Employee2 (Nolock)
Group By DeptID, Salary
)

Select DeptID, Salary from CTE Where r1 = 3;

--second highest
Select Cast(Max(Salary)AS Decimal(10,2)) AS SecondHighSlry
From Employee2 where salary < (Select Max(salary) From Employee2)
------------------------------------------------------------------------------
-- Create Sales Table
CREATE TABLE Sales (
    SaleID INT IDENTITY(1,1) PRIMARY KEY,
    SaleDate DATE NOT NULL,
    Amount DECIMAL(10,2) NOT NULL
);

-- Sample Sales Data for 2023
INSERT INTO Sales (SaleDate, Amount) VALUES
('2023-01-10', 100.50), ('2023-01-15', 120.75), ('2023-01-20', 130.25),
('2023-02-05', 200.00), ('2023-02-18', 220.50),
('2023-03-12', 300.00), ('2023-03-20', 310.00),
('2023-04-02', 400.00), ('2023-04-22', 420.00);

-- Sample Sales Data for 2024
INSERT INTO Sales (SaleDate, Amount) VALUES
('2024-01-08', 250.25), ('2024-01-18', 260.75), ('2024-01-28', 270.50),
('2024-02-10', 380.00), ('2024-02-21', 395.25),
('2024-03-15', 500.00), ('2024-03-25', 510.00),
('2024-04-05', 670.00), ('2024-04-18', 690.00);
-------------------------------------------------------------
--Find the difference in average sales for each month between 2023 and 2024.
Select * From sales (nolock)
Select Avg(Amount)From Sales(nolock)
where Convert(date, SaleDate) between convert(date,'2023-01-01') and convert(date,'2024-12-31');
-------------------------------------

With MonthlySales AS
(
Select Year(SaleDate) AS Yr, Month(SaleDate) As Mn, Avg(Amount) As AvgSales From Sales
Group By Year(SaleDate), Month(SaleDate)
),
YRMnth AS
(
Select Mn, 
Max(Case when Yr = 2023 THEN AvgSales End)AS AvgM2023, 
Max(Case when Yr = 2024 Then Avgsales End) As AvgM2024 From MonthlySales
Group By Mn
)
Select DateName(Month, Datefromparts(2000,MN,1)) AS [Month], (AvgM2024 - AvgM2023) As diff From YRMnth

-----------------------------------------------------

WITH MonthlySales AS (
    SELECT 
        YEAR(SaleDate) AS Yr,
        MONTH(SaleDate) AS Mn,
        AVG(Amount) AS AvgSales
    FROM Sales
    GROUP BY YEAR(SaleDate), MONTH(SaleDate)
), 
Pivoted AS (
    SELECT Mn, [2023] AS Avg2023, [2024] AS Avg2024
    FROM MonthlySales
    PIVOT (
        MAX(AvgSales) FOR Yr IN ([2023], [2024])
    ) AS p
)
SELECT 
    DATENAME(MONTH, DATEFROMPARTS(2000, Mn, 1)) AS [Month],
    (Avg2024 - Avg2023) AS Diff
FROM Pivoted
WHERE Avg2023 IS NOT NULL AND Avg2024 IS NOT NULL
ORDER BY Mn;
--------------------------------------------------
CREATE TABLE Reviews (
    Review_ID INT IDENTITY(1,1) PRIMARY KEY,
    User_ID INT NOT NULL,
    Submit_Date DATE NOT NULL,
    Product_ID INT NOT NULL,
    Stars DECIMAL(3,1) NOT NULL  -- supports ratings like 4.5, 3.0, etc.
);

INSERT INTO Reviews (User_ID, Submit_Date, Product_ID, Stars) VALUES
(101, '2024-01-05', 1, 4.0),
(102, '2024-01-15', 1, 5.0),
(103, '2024-01-20', 2, 3.0),
(104, '2024-01-25', 2, 4.0),

(105, '2024-02-03', 1, 2.0),
(106, '2024-02-10', 1, 3.5),
(107, '2024-02-15', 2, 4.0),
(108, '2024-02-18', 2, 5.0),

(109, '2024-03-02', 1, 4.5),
(110, '2024-03-08', 2, 3.0),
(111, '2024-03-12', 2, 3.5),
(112, '2024-03-20', 1, 5.0);

Select Product_ID PID, DateName(Month,Submit_Date) Mn, Cast(AVG(Stars) As Decimal(5,2)) as r 
From Reviews (nolock)
group by Product_ID,  DateName(Month,Submit_Date)
Order by DateName(Month,Submit_Date), Product_ID 
---------------------------------------------------------------------------

CREATE TABLE Sales1 (
    ProductID INT,
    Amount DECIMAL(10,2)
);

INSERT INTO Sales1 VALUES
(1, 1000),
(2, 1500),
(3, 2500),
(4, 5000);

SELECT 
    ProductID,
    Amount,
    SUM(Amount) OVER() AS TotalSales,
    CAST( (Amount * 100.0) / SUM(Amount) OVER() AS DECIMAL(5,2)) AS ContributionPct
FROM Sales1;
-------------------------------------------
-- Create table
CREATE TABLE Employee3 (
    EmpID INT PRIMARY KEY,
    EmpName VARCHAR(50),
    Salary DECIMAL(10,2),
    ManagerID INT NULL
);
truncate table employee3
-- Insert data
INSERT INTO Employee3 (EmpID, EmpName, Salary, ManagerID) VALUES
(1, 'A', 12000, NULL),   -- CEO (no manager)
(2, 'B', 8000, 1),       -- Manager under A
(3, 'C', 9000, 2),       -- Employee under B
(4, 'D', 7000, 2),       -- Employee under B
(5, 'E', 11000, 1);      -- Employee under A

Select * from Employee3
Select * from employee3 e1 (nolock)
inner join employee3 e2 (nolock) on e1.ManagerID =e2.EmpID
where e1.salary > e2.salary
-----------------------------------------------------------------------------

-- Customer table
CREATE TABLE Customers1 (
    CustomerID INT PRIMARY KEY,
    CustomerName NVARCHAR(100)
);

-- Transactions table
CREATE TABLE Transactions (
    TransactionID INT PRIMARY KEY,
    CustomerID INT,
    TransactionDate DATE,
    Amount DECIMAL(10,2),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

-- Customers
INSERT INTO Customers1 (CustomerID, CustomerName) VALUES
(1, 'Alice'),
(2, 'Bob'),
(3, 'Charlie'),
(4, 'David');

-- Transactions
INSERT INTO Transactions (TransactionID, CustomerID, TransactionDate, Amount) VALUES
(101, 1, '2024-12-10', 500.00),  -- Alice last txn 8 months ago
(102, 2, '2025-07-01', 700.00),  -- Bob recent txn
(103, 3, '2025-01-15', 200.00);  -- Charlie last txn 7 months ago

-- David (4) → no transactions at all

Select * from Customers1
Select * from Transactions


Select C.CustomerID, C.CustomerName from customers1 c (nolock)
left join Transactions t (nolock) on c.customerid = t.customerid 
and t.TransactionDate >= DATEADD(Month , -6, getdate())
where t.TransactionDate is null 
---------------------------------------------------

Create Nonclustered index customerID_Inder on customers1(CustomerID,customername);
------------------------------------------------------------------

