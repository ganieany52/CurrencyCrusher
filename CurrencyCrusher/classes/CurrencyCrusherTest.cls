@isTest
    private class CurrencyCrusherTest {

        @isTest static void testCurrencyCrusher() {

        CurrencyType corporateCurrency = [SELECT Id, IsCorporate, IsoCode FROM CurrencyType WHERE IsCorporate = TRUE];
        CurrencyType nonCorporateCurrency = [SELECT Id, IsActive, ConversionRate, IsoCode FROM CurrencyType WHERE IsActive = TRUE Limit 1];
                
        List<PricebookEntry> pbeStdList = new List<PricebookEntry>();
        List<PricebookEntry> pbeNstdList = new List<PricebookEntry>();
    
        Product2 testProduct = new Product2();
        testProduct.name = 'test product';
        testProduct.IsActive = true;
        insert testProduct;
        
        PricebookEntry pbeStdNCC = new PricebookEntry();
        pbeStdNCC.CurrencyIsoCode = nonCorporateCurrency.IsoCode;
        pbeStdNCC.UnitPrice = 50;
        pbeStdNCC.Product2Id = testProduct.id;
        pbeStdNCC.Pricebook2Id = Test.getStandardPricebookId();
        pbeStdNCC.IsActive = true;
        pbeStdList.add(pbeStdNCC);

        PricebookEntry pbeStdCC = new PricebookEntry();
        pbeStdCC.CurrencyIsoCode = corporateCurrency.IsoCode;
        pbeStdCC.UnitPrice = 100;
        pbeStdCC.Product2Id = testProduct.id;
        pbeStdCC.Pricebook2Id = Test.getStandardPricebookId();
        pbeStdCC.IsActive = true;
        pbeStdList.add(pbeStdCC);

        insert pbeStdList;

        Pricebook2 customPriceBook = new Pricebook2();
        customPriceBook.IsActive = true;
        customPriceBook.Name = 'Custom Price Book';
        insert customPriceBook;

        PricebookEntry pbeCustomNCC = new PricebookEntry();
        pbeCustomNCC.CurrencyIsoCode = nonCorporateCurrency.IsoCode;
        pbeCustomNCC.UnitPrice = 50;
        pbeCustomNCC.Product2Id = testProduct.id;
        pbeCustomNCC.Pricebook2Id = customPriceBook.Id;
        pbeCustomNCC.IsActive = true;
        pbeNstdList.add(pbeCustomNCC);

        PricebookEntry pbeCustomCC = new PricebookEntry();
        pbeCustomCC.CurrencyIsoCode = corporateCurrency.IsoCode;
        pbeCustomCC.UnitPrice = 100;
        pbeCustomCC.Product2Id = testProduct.id;
        pbeCustomCC.Pricebook2Id = customPriceBook.Id;
        pbeCustomCC.IsActive = true;
        pbeNstdList.add(pbeCustomCC);

        insert pbeNstdList;

        Test.startTest();
        CurrencyCrusher bc = new CurrencyCrusher();
        Id batchId = Database.executeBatch(bc);

        CurrencyCrusherSchedule sch = new CurrencyCrusherSchedule();
        String cronStr = '0 0 23 * * ?';
        system.schedule('CurrencyCrusherTestSchedule', cronStr , sch);

        Test.stopTest();
        
        AsyncApexJob jobAfterStop = [SELECT Id, ApexClassId, CompletedDate, CreatedById, CreatedDate, ExtendedStatus,
        JobItemsProcessed, JobType, LastProcessed, LastProcessedOffset, MethodName, NumberOfErrors,
        ParentJobId, Status, TotalJobItems FROM AsyncApexJob WHERE ID = :batchId ];

        PricebookEntry pbeCustomNCCInfo = [SELECT Id, CurrencyIsoCode, Pricebook2.IsActive, Current_Exchange_Rate__c,
        Exclude_from_Exchange_Rate_Updates__c,LastModifiedDate,CreatedDate, UseStandardPrice, IsActive, Pricebook2Id, Product2Id, UnitPrice
        FROM PricebookEntry WHERE Id = :pbeCustomNCC.Id];

        PricebookEntry pbeCustomCCInfo = [SELECT Id, CurrencyIsoCode, Pricebook2.IsActive, Current_Exchange_Rate__c,
        Exclude_from_Exchange_Rate_Updates__c, LastModifiedDate,CreatedDate, IsActive, Pricebook2Id, Product2Id, UnitPrice
        FROM PricebookEntry WHERE Id = :pbeCustomCC.Id];

        System.assertEquals((pbeCustomCCInfo.UnitPrice * pbeCustomNCCInfo.Current_Exchange_Rate__c).setScale(2), pbeCustomNCCInfo.UnitPrice);

        }
    
    }