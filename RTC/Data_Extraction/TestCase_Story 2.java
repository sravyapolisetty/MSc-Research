import java.io.File;
import java.io.IOException;
import java.net.URI;
import java.util.ArrayList;
import java.util.List;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.eclipse.core.runtime.IProgressMonitor;
import org.w3c.dom.Attr;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.ibm.team.links.client.ILinkManager;
import com.ibm.team.links.common.IItemReference;
import com.ibm.team.links.common.ILink;
import com.ibm.team.links.common.ILinkCollection;
import com.ibm.team.links.common.registry.IEndPointDescriptor;
import com.ibm.team.process.client.IProcessClientService;
import com.ibm.team.process.common.IProjectArea;
import com.ibm.team.process.common.IProjectAreaHandle;
import com.ibm.team.repository.client.ITeamRepository;
import com.ibm.team.repository.client.TeamPlatform;
import com.ibm.team.repository.client.ITeamRepository.ILoginHandler;
import com.ibm.team.repository.client.ITeamRepository.ILoginHandler.ILoginInfo;
import com.ibm.team.repository.common.IItemHandle;
import com.ibm.team.repository.common.ItemNotFoundException;
import com.ibm.team.repository.common.TeamRepositoryException;
import com.ibm.team.repository.common.transport.ConnectionException;
import com.ibm.team.repository.common.util.NLS;
import com.ibm.team.workitem.client.IAuditableClient;
import com.ibm.team.workitem.client.IQueryClient;
import com.ibm.team.workitem.common.IAuditableCommon;
import com.ibm.team.workitem.common.IWorkItemCommon;
import com.ibm.team.workitem.common.expression.AttributeExpression;
import com.ibm.team.workitem.common.expression.IQueryableAttribute;
import com.ibm.team.workitem.common.expression.IQueryableAttributeFactory;
import com.ibm.team.workitem.common.expression.QueryableAttributes;
import com.ibm.team.workitem.common.expression.Term;
import com.ibm.team.workitem.common.expression.Term.Operator;
import com.ibm.team.workitem.common.model.AttributeOperation;
import com.ibm.team.workitem.common.model.IWorkItem;
import com.ibm.team.workitem.common.model.WorkItemLinkTypes;
import com.ibm.team.workitem.common.query.IQueryResult;
import com.ibm.team.workitem.common.query.IResolvedResult;
import com.ibm.team.workitem.common.text.WorkItemTextUtilities;


/* 
		 *Sravya Polisetty April 16th 2017*
		 *Last Edited: April 16th 2017
		 *This code is used to fetch all the test cases in DOORS project that are mapped to the stories in RM/RMP projects.
		 *Input: repo url, username, password,Project Area Name
		 *Output:TC_Story.xml. 
		 */
public class TestCase_Story {

private static class LoginHandler implements ILoginHandler, ILoginInfo {
		
		private String UserId;
		private String Password;
		
		private LoginHandler(String userId, String password) {
			UserId= userId;
			Password= password;
		}
		
		public String getUserId() {
			return UserId;
		}
		
		public String getPassword() {
			return Password;
		}
		
		public ILoginInfo challenge(ITeamRepository repository) {
			return this;
		}
	}

	public static void main(String[] args) {
		
		if (args.length < 4) {
			System.out.println("Need <repositoryURI> <user> <password> <project area name>");
			System.exit(1);
		}
		
		String repositoryURI= args[0];
		String userId= args[1];
		String password= args[2];
		String projectAreaName= args[3];
		String workItemType="com.ibm.team.apt.workItemType.story";
		
		
		System.out.println("Project Area : " + projectAreaName);
		System.out.println("Work Item Type : " +workItemType);
		
		try {
			TeamPlatform.startup();
			ITeamRepository repository= login(repositoryURI, userId, password);
			IQueryResult<IResolvedResult<IWorkItem>> result= getResult(repository, projectAreaName,workItemType);
			printResult(result,repository);
			
		} catch (ItemNotFoundException e) {
			System.err.println(e.getMessage());
		} catch (ConnectionException e) {
			System.err.println(e.getMessage());
		} catch (TeamRepositoryException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			TeamPlatform.shutdown();
		}
	}
	
	private static ITeamRepository login(String repositoryURI, String userId, String password) throws TeamRepositoryException {
		ITeamRepository teamRepository= TeamPlatform.getTeamRepositoryService().getTeamRepository(repositoryURI);
		teamRepository.setConnectionTimeout(1000);
		teamRepository.registerLoginHandler(new LoginHandler(userId, password));
		teamRepository.login(null);
		return teamRepository;
	}

	private static void printResult(IQueryResult<IResolvedResult<IWorkItem>> result,ITeamRepository repo) throws TeamRepositoryException {
		try{
			
			DocumentBuilderFactory docFactory = DocumentBuilderFactory.newInstance();
			DocumentBuilder docBuilder = docFactory.newDocumentBuilder();

			// root elements
			Document doc = docBuilder.newDocument();
			Element rootElement = doc.createElement("WI");
			doc.appendChild(rootElement);
		
		System.out.println();
		System.out.println("-------------------------------------------------------------------------------");
		System.out.println(NLS.bind("Story count: {0}", result.getResultSize(null).getTotal()));
		System.out.println("-------------------------------------------------------------------------------");
		
		while (result.hasNext(null)) {
			
			IResolvedResult<IWorkItem> resolved= result.next(null);
			String workItemId= WorkItemTextUtilities.getWorkItemId(resolved.getItem());
			List<String> testCases=getTestCases(resolved.getItem(),repo);
		
			
				Element workItem=doc.createElement("story");
				rootElement.appendChild(workItem);
				
				Attr attrId = doc.createAttribute("id");
				attrId.setValue(workItemId);
				workItem.setAttributeNode(attrId);
				
				Element testCaseDOORS=doc.createElement("TC_DOORS_Story");
				
				for(String i:testCases){
					Element testCaseDesc=doc.createElement("TestCases");
					testCaseDesc.appendChild(doc.createTextNode(i));
					testCaseDOORS.appendChild(testCaseDesc);
				}
				
				workItem.appendChild(testCaseDOORS);
				
					
		}
		
		System.out.print("Done retrieving....writing to XML");
		TransformerFactory transformerFactory = TransformerFactory.newInstance();
		Transformer transformer = transformerFactory.newTransformer();
		DOMSource source = new DOMSource(doc);
		
		StreamResult output = new StreamResult(new File("C:\\TC_Story.xml"));
		transformer.transform(source, output);

		System.out.println("File saved!");	
		
		
		}
		
		catch(Exception e){
			
			e.printStackTrace();
			
		}
	}

private static IQueryResult<IResolvedResult<IWorkItem>> getResult(ITeamRepository repository, String projectAreaName,String workItemType) throws IOException, TeamRepositoryException {
		
		IProcessClientService processClient= (IProcessClientService) repository.getClientLibrary(IProcessClientService.class);
		IQueryClient queryClient= (IQueryClient) repository.getClientLibrary(IQueryClient.class);
		IAuditableClient auditableClient= (IAuditableClient) repository.getClientLibrary(IAuditableClient.class); 
		URI uri= URI.create(projectAreaName.replaceAll(" ", "%20"));
		IProjectArea projectArea= (IProjectArea) processClient.findProcessArea(uri, null, null);
		if (projectArea == null) {
			throw new ItemNotFoundException(NLS.bind("Project area {0} not found", projectAreaName));
		}
		
		
		IQueryableAttribute projectAreaAttribute= findAttribute(projectArea, auditableClient, IWorkItem.PROJECT_AREA_PROPERTY, null);
		
		IQueryableAttribute workItemTypeAttribute= findAttribute(projectArea, auditableClient, IWorkItem.TYPE_PROPERTY, null);
			
		AttributeExpression projectAreaExpression= new AttributeExpression(projectAreaAttribute, AttributeOperation.EQUALS, projectArea);
		
		AttributeExpression workItemTypeExpression=new AttributeExpression(workItemTypeAttribute,AttributeOperation.EQUALS,workItemType);
		
		Term term= new Term(Operator.AND);
		term.add(projectAreaExpression);
		term.add(workItemTypeExpression);
		
		IQueryResult<IResolvedResult<IWorkItem>> queryResults=queryClient.getResolvedExpressionResults(projectArea, term, IWorkItem.FULL_PROFILE);
		queryResults.setLimit(Integer.MAX_VALUE);
		return queryResults;
		
	}
	
private static IQueryableAttribute findAttribute(IProjectAreaHandle projectArea, IAuditableCommon auditableCommon, String attributeId, IProgressMonitor monitor) throws TeamRepositoryException {
	
	IQueryableAttributeFactory factory= QueryableAttributes.getFactory(IWorkItem.ITEM_TYPE);
	return factory.findAttribute(projectArea, attributeId, auditableCommon, monitor);
}
            
private static List<String> getTestCases(IWorkItem workItem, ITeamRepository repo){
	
	try{

		//System.out.println("Getting test case for work item: "+ workItem.getId());
		List<String> testCase=new ArrayList<String>();
		
		ILinkManager linkManager = (ILinkManager) repo.getClientLibrary(ILinkManager.class);

	    IItemReference itemReference = linkManager.referenceFactory().createReferenceToItem(workItem);

	    ILinkCollection linkCollection = linkManager.findLinksBySource(itemReference, null).getAllLinksFromHereOn();


	    for (ILink link: linkCollection) {
	    	if(link.getLinkTypeId().toString().equals(WorkItemLinkTypes.TESTED_BY_TEST_CASE))
	    {
	    		testCase.add(link.getThisEndpointDescriptor(link.getTargetRef()).getDisplayName() + " " + link.getTargetRef().
	    		getComment());
	     
	    		System.out.println(testCase);
	    	}
	    }
	    
	    return testCase;
	
		
		
	}
		
	
	
	catch(Exception e)
	{
		return null;
	}
	
	
}

}
	


