
/* 
		 *Sravya Polisetty March 21st 2017*
		 *Last Edited: April 15th 2017
		 *This code is used to fetch change sets for certain workitems which do not have the changes in the repository
		 *but have changes associated.
		 *Input: repo url, username, password,Project Area Name, Type
		 *Output: WI.xml. 
		 */

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.net.URI;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;


import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.eclipse.core.runtime.IProgressMonitor;
import org.w3c.dom.Attr;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.ibm.team.repository.client.IItemManager;
import com.ibm.team.repository.client.ITeamRepository;
import com.ibm.team.repository.client.TeamPlatform;
import com.ibm.team.repository.client.ITeamRepository.ILoginHandler;
import com.ibm.team.repository.client.ITeamRepository.ILoginHandler.ILoginInfo;
//import com.ibm.team.repository.common.IItemHandle;
import com.ibm.team.repository.common.ItemNotFoundException;
import com.ibm.team.repository.common.TeamRepositoryException;
import com.ibm.team.repository.common.transport.ConnectionException;
import com.ibm.team.repository.common.util.NLS;
import com.ibm.team.scm.client.IConfiguration;
import com.ibm.team.scm.client.IWorkspaceConnection;
import com.ibm.team.scm.client.IWorkspaceManager;
import com.ibm.team.scm.client.SCMPlatform;
import com.ibm.team.scm.common.IChange;
import com.ibm.team.scm.common.IChangeSet;
import com.ibm.team.scm.common.IChangeSetHandle;
import com.ibm.team.scm.common.IComponentHandle;
import com.ibm.team.scm.common.IVersionable;
import com.ibm.team.scm.common.IVersionableHandle;
import com.ibm.team.scm.common.IWorkspaceHandle;
import com.ibm.team.scm.common.dto.IAncestorReport;
import com.ibm.team.scm.common.dto.ILocateChangeSetsSearchCriteria;
import com.ibm.team.scm.common.dto.INameItemPair;
import com.ibm.team.scm.common.dto.IWorkspaceSearchCriteria;
import com.ibm.team.scm.common.internal.dto.WorkspaceSearchCriteria;
import com.ibm.team.filesystem.common.workitems.ILinkConstants;
import com.ibm.team.links.client.ILinkManager;
import com.ibm.team.links.common.IItemReference;
import com.ibm.team.links.common.ILink;
import com.ibm.team.links.common.ILinkCollection;
import com.ibm.team.process.client.IProcessClientService;
import com.ibm.team.process.common.IIteration;
import com.ibm.team.process.common.IProjectArea;
import com.ibm.team.process.common.IProjectAreaHandle;
import com.ibm.team.workitem.client.IAuditableClient;
import com.ibm.team.workitem.client.IQueryClient;
import com.ibm.team.workitem.client.IWorkItemClient;
import com.ibm.team.workitem.common.IAuditableCommon;
import com.ibm.team.workitem.common.expression.AttributeExpression;
import com.ibm.team.workitem.common.expression.IQueryableAttribute;
import com.ibm.team.workitem.common.expression.IQueryableAttributeFactory;
import com.ibm.team.workitem.common.expression.QueryableAttributes;
import com.ibm.team.workitem.common.expression.Term;
import com.ibm.team.workitem.common.expression.Term.Operator;
import com.ibm.team.workitem.common.model.AttributeOperation;
import com.ibm.team.workitem.common.model.IWorkItem;
import com.ibm.team.workitem.common.model.ItemProfile;
import com.ibm.team.workitem.common.model.WorkItemLinkTypes;
import com.ibm.team.workitem.common.query.IQueryResult;
import com.ibm.team.workitem.common.query.IResolvedResult;
import com.ibm.team.workitem.common.text.WorkItemTextUtilities;

public class GetMissingChangeSets {
	

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
		
		if (args.length < 3) {
			System.out.println("Need <repositoryURI> <user> <password>");
			System.exit(1);
		}
		
		String repositoryURI= args[0];
		String userId= args[1];
		String password= args[2];
		
	
		
		try {
			DocumentBuilderFactory docFactory = DocumentBuilderFactory.newInstance();
			DocumentBuilder docBuilder = docFactory.newDocumentBuilder();

			// root elements
			Document doc = docBuilder.newDocument();
			Element rootElement = doc.createElement("WI");
			doc.appendChild(rootElement);
		
			
			String csvFile="C://Odd_Work_Items.csv";
			String line = "";
			BufferedReader br = new BufferedReader(new FileReader(csvFile));
			
			List<String> missingWorkItemList=new ArrayList<String>();
			
			while ((line = br.readLine()) != null) {

                // use comma as separator
				missingWorkItemList.add(line);
			}
			
			br.close();
			
			TeamPlatform.startup();
			ITeamRepository repo= login(repositoryURI, userId, password);
			IWorkItemClient workItemClient = (IWorkItemClient)repo.getClientLibrary(IWorkItemClient.class);
	
			for(String missingWorkItem:missingWorkItemList){
				
				int WorkItemId=Integer.parseInt(missingWorkItem);
				IWorkItem workItem = workItemClient.findWorkItemById(WorkItemId,IWorkItem.FULL_PROFILE.createExtension(
												Arrays.asList(new String[] { IWorkItem.TARGET_PROPERTY })), null);
				List<String> output=new ArrayList<String>();
				output=getChangeSets(workItem,repo);
				doc=printResult(output,workItem,rootElement,doc,repo);
			}
			TeamPlatform.shutdown();
			System.out.print("Done retrieving all work items....writing to XML");
			TransformerFactory transformerFactory = TransformerFactory.newInstance();
			Transformer transformer = transformerFactory.newTransformer();
			DOMSource source = new DOMSource(doc);
			
			StreamResult xmlOutput = new StreamResult(new File("C:\\MissingChangeSets.xml"));
			transformer.transform(source, xmlOutput);
	
			System.out.println("File saved!");	
			
		}
		
		
	catch(Exception e){
			e.printStackTrace();
		}
		finally {
		
		}
	}

	
	private static Document printResult(List<String> output,IWorkItem wi,Element rootElement,Document doc,ITeamRepository repo) throws TeamRepositoryException {
		try{
			
			
			String workItemId= WorkItemTextUtilities.getWorkItemId(wi);
			System.out.println(workItemId);
			
			
			String plannedFor="UnAssigned";
			
			if(wi.getTarget()!=null)
			{
				IAuditableClient auditableClient= (IAuditableClient) repo.getClientLibrary(IAuditableClient.class);
				IIteration iteration = auditableClient.resolveAuditable(wi.getTarget(),ItemProfile.ITERATION_DEFAULT, null); 
			    plannedFor=iteration.getName();
				
			}
			String parentDesc=getParent(wi,repo);
			
			for(String i: output){
				
				
				Element workItem=doc.createElement("workitem");
				rootElement.appendChild(workItem);
				
				Attr attrId = doc.createAttribute("id");
				attrId.setValue(workItemId);
				workItem.setAttributeNode(attrId);
				
				Attr attRelease = doc.createAttribute("plannedFor");
				attRelease.setValue(plannedFor);
				workItem.setAttributeNode(attRelease);
				
				Attr parent=doc.createAttribute("parent");
				parent.setValue(parentDesc);
				workItem.setAttributeNode(parent);
				
				Element file=doc.createElement("file");
				file.appendChild(doc.createTextNode(i));
				workItem.appendChild(file);
			}	
		
			return doc;
		}
		
		catch(Exception e){
			
			return null;
			
		}
		
	}
            
		private static ITeamRepository login(String repositoryURI, String userId, String password) throws TeamRepositoryException {
		ITeamRepository teamRepository= TeamPlatform.getTeamRepositoryService().getTeamRepository(repositoryURI);
		teamRepository.registerLoginHandler(new LoginHandler(userId, password));
		teamRepository.setConnectionTimeout(10000000);
		teamRepository.login(null);
		return teamRepository;
	}
		
		@SuppressWarnings("unchecked")
		public static String pathFinder(ITeamRepository repo, IWorkspaceManager wm, IChangeSet cs, IVersionable vh)
	            throws TeamRepositoryException {
	        String filePath = "";
	        IWorkspaceConnection wsc = workspaceConnectionFinder(repo, wm, cs);
	        IComponentHandle component = cs.getComponent();
	        IConfiguration config = wsc.configuration(component);
	        List<IVersionableHandle> versionableHandleList = new ArrayList<IVersionableHandle>();
	        versionableHandleList.add(vh); 
	        List<IAncestorReport> ancestorReports =config.locateAncestors(versionableHandleList, null);
	        IAncestorReport iAncestorReport = ancestorReports.get(0);
	        List<INameItemPair> reportList = iAncestorReport.getNameItemPairs();
	       
	        
	        if(reportList.isEmpty()){
	        	
	        	return vh.getName();
	        	
	        }
	        else{
	        for (INameItemPair iNameItemPair : reportList) {
	        String temp = iNameItemPair.getName();
	        if (temp != null) {
	            filePath += "/" + temp;
	        }
	        
	        } 
	      }
	        
	        return filePath;

	}

		public static IWorkspaceConnection workspaceConnectionFinder(ITeamRepository repo, IWorkspaceManager wm, IChangeSet cs)

		        throws TeamRepositoryException {
		    IWorkspaceSearchCriteria wsSearchCriteria = WorkspaceSearchCriteria.FACTORY.newInstance();
		    wsSearchCriteria.setKind(IWorkspaceSearchCriteria.STREAMS);
		    
		    List<IWorkspaceHandle> workspaceHandles = wm.findWorkspacesContainingChangeset(cs, wsSearchCriteria,
		            Integer.MAX_VALUE, null);
		    IWorkspaceConnection wsc = wm.getWorkspaceConnection(workspaceHandles.get(0), null);
		    return wsc;
		}
			


	private static List<String> getChangeSets(IWorkItem workItem, ITeamRepository repo)
	{
		
		List<String> output=new ArrayList<String>();
		try
		{
		
		IWorkspaceManager workspaceManager = (IWorkspaceManager)repo.getClientLibrary(IWorkspaceManager.class);
		IItemManager itemManager = repo.itemManager();
		ILinkManager linkManager = (ILinkManager) repo.getClientLibrary(ILinkManager.class);
		IItemReference workItemReference = linkManager.referenceFactory().createReferenceToItem(workItem);
		ILinkCollection linkCollection = linkManager.findLinksByTarget(ILinkConstants.CHANGESET_WORKITEM_LINKTYPE_ID, workItemReference, null).getAllLinksFromHereOn();
		
		if (linkCollection.isEmpty()) {
			output.add("Work item has no change sets");
			return output;
			
		}
		
		List<IChangeSetHandle> changeSetHandles = new ArrayList<IChangeSetHandle>();
		
		for (ILink link: linkCollection) {
			// Change set links should be item references
			IChangeSetHandle changeSetHandle = (IChangeSetHandle) link.getSourceRef().resolve();
			
			changeSetHandles.add(changeSetHandle);
		}
		@SuppressWarnings("unchecked")
		List<IChangeSet> changeSets = itemManager.fetchCompleteItems(changeSetHandles, IItemManager.DEFAULT, null);
		
		for (IChangeSet cs: changeSets) {
			for (Object o: cs.changes()) {
				IChange change = (IChange)o;
				if (change.kind() != IChange.DELETE) {
					IVersionableHandle after = change.afterState();
					if(after!=null){
					IVersionable afterVersionable = workspaceManager.versionableManager().fetchCompleteState(after, null);
					//output.add(pathFinder(repo, workspaceManager,cs, afterVersionable));
					output.add(afterVersionable.getName());
					
					}
				}
				
				
			}
		}
		
		}
		
		catch( Exception e)
		{
			output.add(e.toString());
		}
		return output;
	}


	private static String getParent(IWorkItem workItem, ITeamRepository repo)
	{
		String parent="";
		try
		{
		ILinkManager linkManager = (ILinkManager) repo.getClientLibrary(ILinkManager.class);
		IItemReference workItemReference = linkManager.referenceFactory().createReferenceToItem(workItem);
		ILinkCollection linkCollection = linkManager.findLinksBySource(WorkItemLinkTypes.PARENT_WORK_ITEM, workItemReference,null).getAllLinksFromHereOn();
		
		if (linkCollection.isEmpty()) {
			parent="";
			return parent;
		}
		
		for (ILink link: linkCollection) {
			
			parent=link.getTargetRef().getComment().split(":")[0];
			
		
		}
		return parent;
		}
		
			
		
		catch( Exception e)
		{
			
			return e.toString();
			
		}
	}

}
