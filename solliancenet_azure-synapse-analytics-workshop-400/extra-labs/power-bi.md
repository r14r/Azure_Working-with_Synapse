# Power BI in Synapse Analytics

## Resource naming throughout this lab

For the remainder of this guide, the following terms will be used for various ASA-related resources (make sure you replace them with actual names and values):

| Azure Synapse Analytics Resource  | To be referred to |
| --- | --- |
| Workspace / workspace name | `Workspace` |
| Power BI workspace name | `Synapse 01` |
| SQL Pool | `SqlPool01` |
| Lab schema name | `pbi` |

## Exercise 1 - Power BI and Synapse workspace integration

![Power BI and Synapse workspace integration](media/IntegrationDiagram.png)

### Task 1 - Explore the Power BI linked service in Synapse Studio

1. Start from  [**Azure Synapse Studio**](<https://web.azuresynapse.net/>) and open the **Manage** hub from the left menu.
    ![Manage Azure Synapse Workspace](media/001-LinkWorkspace.png)

2. Beneath **External Connections**, select **Linked Services**, observe that a Linked Service pointing to a pre-created Power BI workspace has already been configured in the environment.
    ![Power BI linked service in Azure Synapse Workspace](media/002-PowerBILinkedService.png)
    Once your Azure Synapse and Power BI workspaces are linked, you can browse your Power BI datasets, edit/create new Power BI Reports directly from the Synapse Studio.

3. In  [**Azure Synapse Studio**](<https://web.azuresynapse.net/>) and navigate to the **Develop** hub using the left menu option.
    ![Develop option in Azure Synapse Workspace](media/003%20-%20PowerBIWorkspace.png)

4. Under **Power BI**, select the linked workspace (**Synapse 01** in the picture bellow) and observe that you have now access to your Power BI datasets and reports, directly from the Synapse Studio.
    ![Explore the linked Power BI workspace in Azure Synapse Studio](media/004%20-%20PowerBIWorkspaceNode.png)
    New reports can be created by selecting **+** at the top of the **Develop** tab. Existing reports can be edited by selecting the report name. Any saved changes will be written back to the Power BI workspace.
    Next, let's explore the linked workspace in Power BI Portal

5. Sign in to the  [**Power BI Portal**](<https://app.powerbi.com/>) and select **Workspaces** from the left menu to check the existence of the Power BI workspace you have configured in the Synapse portal.
    ![Check Power BI workspace in the Power BI portal](media/005%20-%20SynapseWorkspaceInPowerBI.png)

### Task 2 - Create a new datasource to use in Power BI Desktop

1. In [**Azure Synapse Studio**](<https://web.azuresynapse.net/>), select **Develop** from the left menu.

2. Beneath **Power BI**, under the linked Power BI workspace, select **Power BI datasets**.

3. Select **New Power BI dataset** from the top actions menu.

    ![Select the New Power BI dataset option](media/011-NewPBIDataset.png)

4. Select **Start** and make sure you have Power BI Desktop installed on your environment machine.

    ![Start publishing the datasource to be used in Power BI desktop](media/012%20-%20NewPBIDataset.png)

5. Next, select **SQLPool01** as the data source for your Power BI report. You'll be able to select tables from this pool when creating your dataset.

    ![Select SQLPool01 as the datasource of your reports](media/013%20-%20NewPBIDataset.png)

6. Select **Download** to save the **01SQLPool01.pbids** file on your local drive and then select **Continue**.

    ![Download the .pbids file on your local drive ](media/014%20-%20NewPBIDataset.png)

7. Select **Close and refresh** to close the publishing dialog.

    ![Close the datasource publish dialog](media/015%20-%20NewPBIDataset.png)

### Task 3 - Create a new Power BI report in Synapse Studio

1. In [**Azure Synapse Studio**](<https://web.azuresynapse.net/>), select **Develop** from the left menu. Select **+** to create a new SQL Script. Execute the following query to get an approximation of its execution time. This will be the query we'll use to bring data in the Power BI report you'll build later in this exercise.

    ```sql
    SELECT count(*) FROM
    (
        SELECT
            FS.CustomerID
            ,P.Seasonality
            ,D.Year
            ,D.Quarter
            ,D.Month
            ,avg(FS.TotalAmount) as AvgTotalAmount
            ,avg(FS.ProfitAmount) as AvgProfitAmount
            ,sum(FS.TotalAmount) as TotalAmount
            ,sum(FS.ProfitAmount) as ProfitAmount
        FROM
                wwi_pbi.SaleSmall FS
                JOIN wwi_pbi.Product P ON P.ProductId = FS.ProductId
                JOIN wwi_pbi.Date D ON FS.TransactionDateId = D.DateId
        GROUP BY
            FS.CustomerID
            ,P.Seasonality
            ,D.Year
            ,D.Quarter
            ,D.Month
    ) T
    ```

2. To connect to your datasource, open the downloaded .pbids file  in Power BI Desktop. Select the **Microsoft account** option on the left, **Sign in** (with the provided credentials for connecting to the Synapse workspace) and click **Connect**.

    ![Sign in with the Microsoft account and connect](media/021%20-%20ConnectionSettingsPowerBIDesktop.png)

3. Select the **Direct Query** option in the connection settings dialog, since our intention is not to bring a copy of the data into Power BI, but to be able to query the datasource while working with the report visualizations. Click **OK** and wait a few seconds while the connection is configured.

    ![Select Direct Query](media/022%20-%20SelectDirectQuery.png)

4. In the Navigator dialog, right click on the root database note and select **Transform data**.

    ![Database navigator dialog - call transform data](media/022%20-%20Datasource%20Navigator%20.png)


5. In the Power Query editor, open the settings page of the **Source** step in the query. Expand the **Advanced options** section, paste the following query and click **OK**. 

    ![Datasource change dialog](media/024%20-%20Edit%20datasource.png)

    ```sql
    SELECT * FROM
    (
        SELECT
            FS.CustomerID
            ,P.Seasonality
            ,D.Year
            ,D.Quarter
            ,D.Month
            ,avg(FS.TotalAmount) as AvgTotalAmount
            ,avg(FS.ProfitAmount) as AvgProfitAmount
            ,sum(FS.TotalAmount) as TotalAmount
            ,sum(FS.ProfitAmount) as ProfitAmount
        FROM
                wwi_pbi.SaleSmall FS
                JOIN wwi_pbi.Product P ON P.ProductId = FS.ProductId
                JOIN wwi_pbi.Date D ON FS.TransactionDateId = D.DateId
        GROUP BY
            FS.CustomerID
            ,P.Seasonality
            ,D.Year
            ,D.Quarter
            ,D.Month
    ) T
    ```



    Note that this step will take at least 30-40 seconds to execute, since it submits the query directly on the Synapse SQL Pool connection.


6. Select **Close & Apply** on the topmost left corner of the editor window to apply the query and fetch the initial schema in the Power BI designer window.

    ![Save query properties](media/026%20-%20CloseAndApply.png)

7. Back to the Power BI report editor, expand the **Visualizations** menu on the right, and drag a **Line and stacked column chart** on the report canvas.

    ![Create new visualization chart](media/027%20-%20CreateVisualization.png)

8. Select the newly created chart to expand it's properties pane. Using the expanded **Fields** menu, configure the visualization as follows:
     - **Shared axis**: `Year`, `Quarter`
     - **Column series**: `Seasonality`
     - **Column values**: `TotalAmount`
     - **Line values**: `ProfitAmount`

    ![Configure chart properties](media/028%20-%20ConfigureVisualization.png)

9. Switching back to the Azure Synapse Studio, you can check the query executed while configuring the visualization in the Power BI Desktop application. Open the **Monitor** hub, and under the **Activities** section, open the **SQL requests** monitor. Make sure you select **SQLPool01** in the Pool filter, as by default  SQL on-demand is selected.

    ![Open query monitoring from Synapse Studio](media/029%20-%20MonitorQueryExecution.png)

10. Identify the query behind your visualization in the topmost requests you see in the log and observe the duration which is about 30 seconds. Use the **Request content** option to look into the actual query submitted from Power BI Desktop.

    ![Check the request content in the monitor](media/030%20-%20CheckRequestContent.png)

    ![View query submitted from Power BI](media/031%20-%20QueryRequestContent.png)

11. Back to the Power BI Desktop application, Save and Publish the created report. Make sure that, in Power BI Desktop you are signed in  with the same account you use in the Power BI portal and in Azure Synapse. You can switch to the proper account from the right topmost corner of the window. In the **Publish to Power BI** dialog, select the workspace you linked to Synapse, named **Synapse 01** in our demonstration.
   
    ![Publish report to the linked workspace](media/032%20-%20Publish.png)

After the operation completes with success, you should be able to see this report published in the Power BI portal, as well as in the Synapse Studio, Develop hub, under the Power BI reports node.

## Exercise 2 - Optimizing integration with Power BI

### Task 1 - Explore Power BI optimization options

Let's recall the performance optimization options we have when integrating Power BI reports in Azure Synapse Analytics, among which we'll demonstrate the use of Result-set caching and materialized views options later in this exercise.

![Power BI performance optimization options](media/power-bi-optimization.png)

### Task 2 - Improve performance with materialized views

1. In [**Azure Synapse Studio**](<https://web.azuresynapse.net/>), select **Develop** from the left menu. Select **+** to create a new SQL Script. Execute the following query to get an approximation of its execution time:

2. Run the following query to get an estimated execution plan and observe the total cost and number of operations.

    ```sql
    EXPLAIN
    SELECT * FROM
    (
        SELECT
        FS.CustomerID
        ,P.Seasonality
        ,D.Year
        ,D.Quarter
        ,D.Month
        ,avg(FS.TotalAmount) as AvgTotalAmount
        ,avg(FS.ProfitAmount) as AvgProfitAmount
        ,sum(FS.TotalAmount) as TotalAmount
        ,sum(FS.ProfitAmount) as ProfitAmount
    FROM
            wwi.SaleSmall FS
            JOIN wwi_poc.Product P ON P.ProductId = FS.ProductId
            JOIN wwi_poc.Date D ON FS.TransactionDateId = D.DateId
        GROUP BY
            FS.CustomerID
            ,P.Seasonality
            ,D.Year
            ,D.Quarter
            ,D.Month
    ) T
    ```

3. The results should look like this:

    ```xml
    <?xml version="1.0" encoding="utf-8"?>
    <dsql_query number_nodes="1" number_distributions="60" number_distributions_per_node="60">
        <sql>SELECT count(*) FROM
    (
        SELECT
        FS.CustomerID
        ,P.Seasonality
        ,D.Year
        ,D.Quarter
        ,D.Month
        ,avg(FS.TotalAmount) as AvgTotalAmount
        ,avg(FS.ProfitAmount) as AvgProfitAmount
        ,sum(FS.TotalAmount) as TotalAmount
        ,sum(FS.ProfitAmount) as ProfitAmount
    FROM
            wwi.SaleSmall FS
            JOIN wwi_poc.Product P ON P.ProductId = FS.ProductId
            JOIN wwi_poc.Date D ON FS.TransactionDateId = D.DateId
        GROUP BY
            FS.CustomerID
            ,P.Seasonality
            ,D.Year
            ,D.Quarter
            ,D.Month
    ) T</sql>
        <dsql_operations total_cost="10.61376" total_number_operations="12">
    ```

4. Create a materialized view that can support the above query:

    ```sql
    CREATE MATERIALIZED VIEW
    wwi_pbi.mvCustomerSales
    WITH
    (
        DISTRIBUTION = HASH( CustomerId )
    )
    AS
    SELECT
        FS.CustomerID
        ,P.Seasonality
        ,D.Year
        ,D.Quarter
        ,D.Month
        ,sum(FS.TotalAmount) as TotalAmount
        ,sum(FS.ProfitAmount) as ProfitAmount
    FROM
        wwi.SaleSmall FS
        JOIN wwi_poc.Product P ON P.ProductId = FS.ProductId
        JOIN wwi_poc.Date D ON FS.TransactionDateId = D.DateId
    GROUP BY
        FS.CustomerID
        ,P.Seasonality
        ,D.Year
        ,D.Quarter
        ,D.Month
    ```

5. Run the following query to check that it actually hits the created materialized view.

    ```sql
    EXPLAIN
    SELECT * FROM
    (
    SELECT
    FS.CustomerID
    ,P.Seasonality
    ,D.Year
    ,D.Quarter
    ,D.Month
    ,avg(FS.TotalAmount) as AvgTotalAmount
    ,avg(FS.ProfitAmount) as AvgProfitAmount
    ,sum(FS.TotalAmount) as TotalAmount
    ,sum(FS.ProfitAmount) as ProfitAmount
    FROM
        wwi_pbi.SaleSmall FS
        JOIN wwi_pbi.Product P ON P.ProductId = FS.ProductId
        JOIN wwi_pbi.Date D ON FS.TransactionDateId = D.DateId
    GROUP BY
        FS.CustomerID
        ,P.Seasonality
        ,D.Year
        ,D.Quarter
        ,D.Month
    ) T

    ```

6. Next move back to the Power BI Desktop report and hit the Refresh data button to submit the query again.

    ![Refresh data to hit the materialized view](media/041%20-%20Refreshdata.png)

7. Check the duration of the query again in Synapse Studio, in the monitoring hub, SQL Requests monitor. Notice that now it runs almost instantly (Duration = 0s).

8. Run the following query to drop the created materialized view

    ```sql
    DROP VIEW [wwi_pbi].[mvCustomerSales]
    GO

    ```

### Task 3 - Improve performance with result-set caching

1. Switch back to the Develop hub in Synapse Studio. Check if result set caching is on in the current SQL pool:

    ```sql
    SELECT
        name
        ,is_result_set_caching_on
    FROM
        sys.databases
    ```

2. If `False` is returned for your SQL pool, run the following query to activate it (you need to run it on the `master` database and replace `SQLPool01` with the name of your SQL pool):

    ```sql
    ALTER DATABASE [SQLPool01]
    SET RESULT_SET_CACHING ON
    ```

    >**Important**
    >
    >The operations to create result set cache and retrieve data from the cache happen on the control node of a Synapse SQL pool instance. When result set caching is turned ON, running queries that return large result set (for example, >1GB) can cause high throttling on the control node and slow down the overall query response on the instance. Those queries are commonly used during data exploration or ETL operations. To avoid stressing the control node and cause performance issue, users should turn OFF result set caching on the database before running those types of queries.

3. Next move back to the Power BI Desktop report and hit the **Refresh** button to submit the query again. 

    ![Refresh data to hit the materialized view](media/041%20-%20Refreshdata.png)

4. Check the duration of the query again in Synapse Studio, in the Monitoring hub - SQL Requests page. Notice that now it runs almost instantly (Duration = 0s).


## Exercise 3 - Visualize data with SQL Serverless

![Connecting to SQL Serverless](media/031%20-%20QuerySQLOnDemand.png)

### Task 1 - Explore the data lake with SQL Serverless

First, let's prepare the Power BI report query by exploring the data source we'll use for visualizations. In this exercise, we'll use the SQL-on demand instance from your Synapse workspace.

1. In [Azure Synapse Studio](https://web.azuresynapse.net), navigate to the **Data** hub and select the **Linked** sources tab.

    ![Explore parquet file structure in SQL on-demand](media/032%20-%20Open%20Data%20Linked.png)

2. Under the **Azure Data Lake Storage Gen2** group, select the Primary Data Lake (first node) and expand to the **wwi-02** file system. Follow this path: `wwi-02/sale-small/Year=2019/Quarter=Q1/Month=1/Day=20190101` to explore the folders structure.

    ![Explore Data Lake filesystem structure](media/033%20-%20ExploreFileSystemStructure.png)

3. Right-click on the parquet file and select **New SQL Script -> Select TOP 100 Rows**. 

    ![Generate select top script to query parquet file structure](media/034%20-%20Generate%20select%20script.png)

4. Run the generated script to preview data stored in the parquet file.
    
    ![Preview data structure in parquet file](media/035%20-%20Data%20structure%20in%20parquet%20file.png)

5. Now let's prepare the query we want to use next in the Power BI report. The query will extract the sum of amount and profit by day for a given month. Let's take for example January 2019. Notice the use of wildcards for the filepath that will reference all the files corresponding to one month. Paste and run the following query on the SQL-on demand instance.

    ```sql
    -- type your sql script here, we now have intellisense
        SELECT
            SUBSTRING(result.filename(), 12, 4) as Year
            ,SUBSTRING(result.filename(), 16, 2) as Month
            ,SUBSTRING(result.filename(), 18, 2) as Day
            ,SUM(TotalAmount) as TotalAmount
            ,SUM(ProfitAmount) as ProfitAmount
            ,COUNT(*) as TransactionsCount
        FROM
            OPENROWSET(
                BULK 'https://asadatalake216969.dfs.core.windows.net/wwi-02/sale-small/Year=2019/Quarter=Q1/Month=1/*/*.parquet',
                FORMAT='PARQUET'
            ) AS [result]
        GROUP BY
            result.filename()
    ```

### Task 2 - Create a Power BI report using SQL Serverless

1. In the [Azure Portal](https://portal.azure.com), navigate to your Synapse Workspace, in **Overview** tab and copy the SQL on-demand endpoint as in the image bellow:
   
    ![Identify endpoint for SQL on-demand](media/036%20-%20Configure%20Connection%20to%20SqlOnDemand.png)

2. In Power BI desktop, create a new empty report, and next, in the top menu go to **Home** -> **Get Data**. Select **Azure** -> **Azure Synapse Analytics (SQL DW)** as in the image bellow and then click **Connect**:
   
    ![Identify endpoint for SQL on-demand](media/037%20-%20GetData.png)

3. Enter the endpoint to SQL on-demand identified at the first step and paste the prepared query in the expanded **Advanced options** section of the SQL Server database dialog:
   
    ![SQL Connection dialog](media/038%20-%20Configure%20Connection.png)

4. Select **Load** in the preview data window and wait for the connection to be configured.
    ![Preview data](media/039%20-%20Preview%20data.png)

5. After the **Fields** menu is populated, drag a **Line chart** from the **Visualizations** toolbar menu and configure it as detailed in the image bellow, to show Profit, Amount and Transactions count by day.

    ![Preview data](media/040%20-%20Configure%20line%20chart%20axes.png)

6. Select the line chart visualization and cofigure it to sort by Date of transaction.
   
     ![Sort ascending](media/041%20-%20Sort%20ascending.png)

     ![Sort by Date](media/042%20-%20Sort%20by%20Date.png)
