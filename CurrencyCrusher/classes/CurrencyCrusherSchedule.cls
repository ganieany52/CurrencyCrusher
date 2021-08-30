/*********************************************************************************
        Name        :        CurrencyCrusherSchedule
        Author      :        Logan Ganieany
        Date        :        07 Aug 2021
        Description :        Implements the Schedulable Interface for the Currency Crusher Batch Class
**********************************************************************************/
public class CurrencyCrusherSchedule implements Schedulable {

    public void execute(SchedulableContext SC) {
        //Execute batch
        CurrencyCrusher b = new CurrencyCrusher(); 
        database.executebatch(b,5);     
    }
    
}