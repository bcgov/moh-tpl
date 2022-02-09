public class Client_DuplicateCheck_Controller {
 public static Id createAccount (Account acc)
    {
        insert acc;
        return acc.Id;
    }
	 @AuraEnabled
    public static String GetAccount (Decimal acc)
    {
        String Message;
        System.debug('test call from save');
		list<Account> accList=[Select id from Account where PHN__c =: acc limit 1];
        if(accList.size()>0){
          Message='Your Account already existed';  
        }else{
            
            Message='Your Account Not existed with the Name : '+accList[0].name; 
        }
        return Message;
    }

}