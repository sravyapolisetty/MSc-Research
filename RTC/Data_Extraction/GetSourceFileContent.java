
/* 
		 *Sravya Polisetty May 15th 2017*
		 *Last Edited: April 15th 2017
		 *This code is used to get the content of a source code file in RTC RM and RMP projects. 
		 *Input: repo url, username, password,Project Area Name, file name
		 *Output: FC.xml. 
		 */

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.net.URI;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

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
import com.ibm.team.scm.common.IFolderHandle;
import com.ibm.team.scm.common.IVersionable;
import com.ibm.team.scm.common.IVersionableHandle;
import com.ibm.team.scm.common.IWorkspaceHandle;
import com.ibm.team.scm.common.dto.IAncestorReport;
import com.ibm.team.scm.common.dto.INameItemPair;
import com.ibm.team.scm.common.dto.IWorkspaceSearchCriteria;
import com.ibm.team.scm.common.internal.dto.WorkspaceSearchCriteria;
import com.ibm.team.filesystem.client.FileSystemCore;
import com.ibm.team.filesystem.client.IFileContentManager;
import com.ibm.team.filesystem.common.IFileContent;
import com.ibm.team.filesystem.common.IFileItem;
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

public class GetSourceFileContent {
	

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
			
			String csvFile="C://Work_Items.csv";
			String line = "";
			BufferedReader br = new BufferedReader(new FileReader(csvFile));
			
			List<String> workItemList=new ArrayList<String>();
			
			while ((line = br.readLine()) != null) {

                // use comma as separator
				workItemList.add(line);
			}
			
			br.close();
	
			TeamPlatform.startup();
			ITeamRepository repo= login(repositoryURI, userId, password);
			IWorkItemClient workItemClient = (IWorkItemClient)repo.getClientLibrary(IWorkItemClient.class);
	
			for(String WorkItem:workItemList){
				
			int WorkItemId=Integer.parseInt(WorkItem);
			System.out.println("Retrieving file conteen of "+WorkItemId);
			boolean parentFolder=new File("C://Sravya_RTC_Source_Code_Files//"+WorkItemId).mkdirs();
			System.out.println(parentFolder);
			IWorkItem workItem = workItemClient.findWorkItemById(WorkItemId,IWorkItem.FULL_PROFILE.createExtension(
											Arrays.asList(new String[] { IWorkItem.TARGET_PROPERTY })), null);

			System.out.println("Retrieving Change sets");
			getChangeSets(WorkItemId,workItem,repo);
			
		} 
			TeamPlatform.shutdown();
		}
		catch (ItemNotFoundException e) {
			System.err.println(e.getMessage());
		} catch (ConnectionException e) {
			System.err.println(e.getMessage());
		} catch (TeamRepositoryException e) {
			e.printStackTrace();
		} catch(Exception e){
			e.printStackTrace();
		}
		finally {
		
		}
	}

	private static ITeamRepository login(String repositoryURI, String userId, String password) throws TeamRepositoryException {
		ITeamRepository teamRepository= TeamPlatform.getTeamRepositoryService().getTeamRepository(repositoryURI);
		teamRepository.registerLoginHandler(new LoginHandler(userId, password));
		teamRepository.setConnectionTimeout(10000000);
		teamRepository.login(null);
		return teamRepository;
	}
	
	public static IWorkspaceConnection workspaceConnectionFinder(ITeamRepository repo, IWorkspaceManager wm, IChangeSet cs)
	        throws TeamRepositoryException {
	   
		IWorkspaceSearchCriteria wsSearchCriteria = WorkspaceSearchCriteria.FACTORY.newInstance();
	    wsSearchCriteria.setKind(IWorkspaceSearchCriteria.STREAMS);
	    List<IWorkspaceHandle> workspaceHandles = wm.findWorkspacesContainingChangeset(cs, wsSearchCriteria,
	            Integer.MAX_VALUE, new SysoutProgressMonitor());
	    IWorkspaceConnection wsc = SCMPlatform.getWorkspaceManager(repo).getWorkspaceConnection(workspaceHandles.get(0),null);
	    return wsc;
	}
			
		public static IVersionableHandle findFile(IFolderHandle root,
				IConfiguration iconfig, String fileName, IProgressMonitor monitor)
				throws TeamRepositoryException {
				 
				String fileNamePath[] = { fileName };
				IVersionableHandle filePathHandle = null;
				 
				// Check if file at this folder level
				filePathHandle = iconfig.resolvePath(root, fileNamePath, monitor);
				if (filePathHandle != null) {
				return filePathHandle;
				}
				 
				System.out.println("Searching for file " + fileName);
				// Check this file sub folders
				
				@SuppressWarnings("unchecked")
				Map<String, IVersionableHandle> childEntries = iconfig.childEntries(root, monitor);
				for (Map.Entry<String, IVersionableHandle> next : childEntries
				.entrySet()) {
				IVersionableHandle nextVersionable = next.getValue();
				if (nextVersionable instanceof IFolderHandle) {
				filePathHandle = findFile((IFolderHandle) nextVersionable,
				iconfig, fileName, monitor);
				if (filePathHandle != null) {
				System.out.println("Found file " + fileName);
				break;
				}
				}
				}
				return filePathHandle;
				}

		public static void readFileContent(IWorkspaceConnection streamConnection,IComponentHandle componentHandle, 
				ITeamRepository repo,int WorkItemId,String fileName) throws TeamRepositoryException, IOException {
				 
				IFileItem fileItem = null;
				IFileContentManager contentManager = FileSystemCore.getContentManager(repo);
				// Find file handle
				IConfiguration iconfig = (IConfiguration) streamConnection.configuration(componentHandle);
				IFolderHandle root = iconfig.rootFolderHandle(null);
				IVersionableHandle filePathHandle = findFile(root, iconfig, fileName,null);
				 
				// Check if file found
				if (filePathHandle == null) {
				throw new FileNotFoundException("File not found.");
				} else {
				System.out.println("Found file: " + fileName);
				}
				 
				// Fetch file complete item
				IVersionable filePath = (IVersionable) iconfig.fetchCompleteItem(filePathHandle, null);
				if (filePath.hasFullState()) {
					fileItem = (IFileItem) filePath.getFullState();
				} 
				else {
					throw new TeamRepositoryException("Could not find file item");
				}
				// Get file content
				IFileContent content = fileItem.getContent();
				ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
				contentManager.retrieveContent(fileItem, content, outputStream, null);
				
				 
				Writer writer=null;
				writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream("C://Sravya_RTC_Source_Code_Files//"
											+WorkItemId+"//"+fileName+".txt"), "utf-8"));
				writer.write(outputStream.toString("UTF-8"));
				
				writer.close();
				}

		private static void getChangeSets(int WorkItemId,IWorkItem workItem, ITeamRepository repo)
		{
			
			String fileName="";
			
			try
			{
			
			IWorkspaceManager workspaceManager = (IWorkspaceManager)repo.getClientLibrary(IWorkspaceManager.class);
			IItemManager itemManager = repo.itemManager();
			ILinkManager linkManager = (ILinkManager) repo.getClientLibrary(ILinkManager.class);
			IItemReference workItemReference = linkManager.referenceFactory().createReferenceToItem(workItem);
			ILinkCollection linkCollection = linkManager.findLinksByTarget(ILinkConstants.CHANGESET_WORKITEM_LINKTYPE_ID, workItemReference, new SysoutProgressMonitor()).getAllLinksFromHereOn();

			List<IChangeSetHandle> changeSetHandles = new ArrayList<IChangeSetHandle>();
			
			for (ILink link: linkCollection) {
				// Change set links should be item references
				IChangeSetHandle changeSetHandle = (IChangeSetHandle) link.getSourceRef().resolve();
				
				changeSetHandles.add(changeSetHandle);
			}
			@SuppressWarnings("unchecked")
			List<IChangeSet> changeSets = itemManager.fetchCompleteItems(changeSetHandles, IItemManager.DEFAULT, new SysoutProgressMonitor());
			
			for (IChangeSet cs: changeSets) {
				for (Object o: cs.changes()) {
					IChange change = (IChange)o;
					if (change.kind() != IChange.DELETE) {
						IVersionableHandle after = change.afterState();
						if(after!=null){
						IVersionable afterVersionable = workspaceManager.versionableManager().fetchCompleteState(after, new SysoutProgressMonitor());
						 IWorkspaceConnection wsc = workspaceConnectionFinder(repo, workspaceManager, cs);
						 IComponentHandle component = cs.getComponent();
						 System.out.println("Finding the file path");
						 fileName=afterVersionable.getName();
						 System.out.println("Attempting to read file content");
						 readFileContent(wsc,component,repo,WorkItemId,fileName);
						
						}
					}
					
					
				}
			}
			
			}
			
			catch( Exception e)
			{
				System.out.println(e.getMessage());
			}
			
			
		}

}
