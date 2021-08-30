/*********************************************************************************
        Name        :        CurrencyCrusher 
        Author      :        Logan Ganieany
        Date        :        03 Aug 2021
        Description :        Batch class to Update all Non-Corporate Currency pricebook entries to the correct price based on the Corporate Currency price
**********************************************************************************/

public class CurrencyCrusher implements Database.Batchable<sObject> {
        public string query;

    public Database.QueryLocator start(Database.BatchableContext BC) {
        query = 'SELECT Id, Name, Exclude_from_Exchange_Rate_Updates__c, IsActive FROM Product2 WHERE IsActive = TRUE AND Exclude_from_Exchange_Rate_Updates__c = FALSE';
        return database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<Product2> productList) {

        CurrencyType corporateCurrency = [SELECT Id, IsCorporate, IsoCode FROM CurrencyType WHERE IsCorporate = TRUE]; //get the corporate currency for the org

        String corporateCurrencyIsoCode = corporateCurrency.IsoCode;

        Currency_Crusher_Setting__mdt currencyCrusherSettings = [SELECT MasterLabel, Do_Not_Update_PBEs_Set_to_Zero__c, QualifiedApiName  FROM Currency_Crusher_Setting__mdt];

        Map<String, PricebookEntry> cCPBEsMap = new Map<String, PricebookEntry>(); //get map of all corporate currency price book entries
        
        List<PricebookEntry> cCPBEsList = [SELECT Id, Name, CurrencyIsoCode, Current_Exchange_Rate__c,
        Exclude_from_Exchange_Rate_Updates__c, IsActive, Pricebook2.Name, Product2Id, Pricebook2.Exclude_from_Exchange_Rate_Updates__c,
        Pricebook2.IsActive, Pricebook2Id, UnitPrice
        FROM PricebookEntry
        WHERE IsActive = TRUE
        AND Pricebook2.IsActive = TRUE
        AND CurrencyIsoCode = :corporateCurrencyIsoCode
        AND Product2Id in : productList];

        String pbIdAndProdIdKey;
        for (PricebookEntry cCPbe : cCPBEsList) {
            pbIdAndProdIdKey = cCPbe.Product2Id +''+ cCPbe.Pricebook2Id; //create a map with a special key of product2Id+pricebook2Id for the corporateCurrency records
            cCPBEsMap.put(pbIdAndProdIdKey, cCPbe);
        }

        //get all non corporate currency price book entries
        //we don't want to try and update a pbe that is using the standard price or it will error
        //if the non corporate currency pbe is 0, we want it to stay at 0
        String nonCCPBEsQuery = 'SELECT Id, Name, CurrencyIsoCode, Current_Exchange_Rate__c, Exclude_from_Exchange_Rate_Updates__c, IsActive, Pricebook2.Name, Product2Id, Pricebook2.Exclude_from_Exchange_Rate_Updates__c,Pricebook2.IsActive, Pricebook2Id, UnitPrice';
        nonCCPBEsQuery += ' FROM PricebookEntry';
        nonCCPBEsQuery += ' WHERE IsActive = TRUE';
        nonCCPBEsQuery += ' AND Pricebook2.IsActive = TRUE';
        nonCCPBEsQuery += ' AND CurrencyIsoCode != :corporateCurrencyIsoCode';
        nonCCPBEsQuery += ' AND Exclude_from_Exchange_Rate_Updates__c = FALSE';
        nonCCPBEsQuery += ' AND Pricebook2.Exclude_from_Exchange_Rate_Updates__c = FALSE';
        nonCCPBEsQuery += ' AND UseStandardPrice = FALSE ';
        If (currencyCrusherSettings.Do_Not_Update_PBEs_Set_to_Zero__c == true) {
            nonCCPBEsQuery += ' AND UnitPrice != 0';
        }
        nonCCPBEsQuery += ' AND Product2Id in : productList';

        List<PricebookEntry> nonCCPBEs = Database.query(nonCCPBEsQuery);

        decimal newPrice;
        string pbIdAndProdIdKey2;
        List<PricebookEntry> nonCCPbesToUpdate = new List<PricebookEntry>();

        for (PricebookEntry nonCCPbe : nonCCPBEs) {
            pbIdAndProdIdKey2 = nonCCPbe.Product2Id +''+ nonCCPbe.Pricebook2Id;
            if (cCPBEsMap.containsKey(pbIdAndProdIdKey2)) { //the issue would be if a non corporate currency pricebook entry didn't have a corporate currency counter part
                newPrice = (cCPBEsMap.get(pbIdAndProdIdKey2).UnitPrice * nonCCPbe.Current_Exchange_Rate__c).setScale(2);
                nonCCPbe.UnitPrice = newPrice;
                nonCCPbesToUpdate.add(nonCCPbe);
                System.debug('New Price for ' + nonCCPbe.Name + ' In Price Book ' + nonCCPbe.Pricebook2.Name + ' is ' + newPrice + ' for Currency ' + nonCCPbe.CurrencyIsoCode);
            }
            else{
                System.debug('No Corporate Currency Price Book Entry Found for Product ' + nonCCPbe.Name + ' Price Book Entry ID is ' + nonCCPbe.Id);
            }
            
        }
        if (!nonCCPbesToUpdate.isEmpty()) {
            update nonCCPbesToUpdate;
        }

    }
    public void finish(Database.BatchableContext BC) {
    }
}