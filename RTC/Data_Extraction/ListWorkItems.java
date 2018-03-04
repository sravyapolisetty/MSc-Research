import java.io.IOException;



import java.net.URI;

import java.util.ArrayList;

import java.util.List;

import java.util.Set;

import java.util.TreeSet;



import org.eclipse.core.runtime.IProgressMonitor;



import com.ibm.team.repository.client.IItemManager;

import com.ibm.team.repository.client.ITeamRepository;

import com.ibm.team.repository.client.TeamPlatform;

import com.ibm.team.repository.client.ITeamRepository.ILoginHandler;

import com.ibm.team.repository.client.ITeamRepository.ILoginHandler.ILoginInfo;

import com.ibm.team.repository.common.ItemNotFoundException;

import com.ibm.team.repository.common.TeamRepositoryException;

import com.ibm.team.repository.common.transport.ConnectionException;

import com.ibm.team.repository.common.util.NLS;

import com.ibm.team.scm.client.IWorkspaceManager;

import com.ibm.team.scm.common.IChange;

import com.ibm.team.scm.common.IChangeSet;

import com.ibm.team.scm.common.IChangeSetHandle;

import com.ibm.team.scm.common.IVersionable;

import com.ibm.team.scm.common.IVersionableHandle;

import com.ibm.team.filesystem.common.workitems.ILinkConstants;

import com.ibm.team.links.client.ILinkManager;

import com.ibm.team.links.common.IItemReference;

import com.ibm.team.links.common.ILink;

import com.ibm.team.links.common.ILinkCollection;

import com.ibm.team.process.client.IProcessClientService;

import com.ibm.team.process.common.IProjectArea;

import com.ibm.team.process.common.IProjectAreaHandle;



import com.ibm.team.workitem.client.IAuditableClient;

import com.ibm.team.workitem.client.IQueryClient;

import com.ibm.team.workitem.common.IAuditableCommon;

import com.ibm.team.workitem.common.expression.AttributeExpression;

import com.ibm.team.workitem.common.expression.IQueryableAttribute;

import com.ibm.team.workitem.common.expression.IQueryableAttributeFactory;

import com.ibm.team.workitem.common.expression.QueryableAttributes;

import com.ibm.team.workitem.common.expression.Term;

import com.ibm.team.workitem.common.expression.Term.Operator;

import com.ibm.team.workitem.common.model.AttributeOperation;

import com.ibm.team.workitem.common.model.IWorkItem;

import com.ibm.team.workitem.common.query.IQueryResult;

import com.ibm.team.workitem.common.query.IResolvedResult;

import com.ibm.team.workitem.common.text.WorkItemTextUtilities;



public class Sample {


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



try {

TeamPlatform.startup();

ITeamRepository repository= login(repositoryURI, userId, password);

IQueryResult<IResolvedResult<IWorkItem>> result= getResult(repository, projectAreaName);

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



private static void printResult(IQueryResult<IResolvedResult<IWorkItem>> result,ITeamRepository repo) throws TeamRepositoryException {


System.out.println();

System.out.println("-------------------------------------------------------------------------------");

System.out.println(NLS.bind("WorkItem count: {0}", result.getResultSize(null).getTotal()));

System.out.println("-------------------------------------------------------------------------------");


while (result.hasNext(null)) {

IResolvedResult<IWorkItem> resolved= result.next(null);

String workItemId= WorkItemTextUtilities.getWorkItemId(resolved.getItem());

System.out.println(workItemId);

Set<String> changedFilesAndFolders=getChangeSets(resolved.getItem(),repo);

for (String fileOrFilderName: changedFilesAndFolders) {

System.out.println("\t"+fileOrFilderName);

}


}

}



private static IQueryResult<IResolvedResult<IWorkItem>> getResult(ITeamRepository repository, String projectAreaName) throws IOException, TeamRepositoryException {


IProcessClientService processClient= (IProcessClientService) repository.getClientLibrary(IProcessClientService.class);

IQueryClient queryClient= (IQueryClient) repository.getClientLibrary(IQueryClient.class);

IAuditableClient auditableClient= (IAuditableClient) repository.getClientLibrary(IAuditableClient.class);


URI uri= URI.create(projectAreaName.replaceAll(" ", "%20"));

IProjectArea projectArea= (IProjectArea) processClient.findProcessArea(uri, null, null);

if (projectArea == null) {

throw new ItemNotFoundException(NLS.bind("Project area {0} not found", projectAreaName));

}


IQueryableAttribute projectAreaAttribute= findAttribute(projectArea, auditableClient, IWorkItem.PROJECT_AREA_PROPERTY, null);

AttributeExpression projectAreaExpression= new AttributeExpression(projectAreaAttribute, AttributeOperation.EQUALS, projectArea);


Term term= new Term(Operator.AND);

term.add(projectAreaExpression);


return queryClient.getResolvedExpressionResults(projectArea, term, IWorkItem.FULL_PROFILE);

}



private static ITeamRepository login(String repositoryURI, String userId, String password) throws TeamRepositoryException {

ITeamRepository teamRepository= TeamPlatform.getTeamRepositoryService().getTeamRepository(repositoryURI);

teamRepository.registerLoginHandler(new LoginHandler(userId, password));

teamRepository.login(null);

return teamRepository;

}




private static IQueryableAttribute findAttribute(IProjectAreaHandle projectArea, IAuditableCommon auditableCommon, String attributeId, IProgressMonitor monitor) throws TeamRepositoryException {

IQueryableAttributeFactory factory= QueryableAttributes.getFactory(IWorkItem.ITEM_TYPE);

return factory.findAttribute(projectArea, attributeId, auditableCommon, monitor);

}


private static Set<String> getChangeSets(IWorkItem workItem, ITeamRepository repo)


{

try

{


IWorkspaceManager workspaceManager = (IWorkspaceManager)repo.getClientLibrary(IWorkspaceManager.class);

IItemManager itemManager = repo.itemManager();

ILinkManager linkManager = (ILinkManager) repo.getClientLibrary(ILinkManager.class);

IItemReference workItemReference = linkManager.referenceFactory().createReferenceToItem(workItem);

ILinkCollection linkCollection = linkManager.findLinksByTarget(ILinkConstants.CHANGESET_WORKITEM_LINKTYPE_ID, workItemReference, new SysoutProgressMonitor()).getAllLinksFromHereOn();


if (linkCollection.isEmpty()) {

System.out.println("Work item has no change sets.");

//System.exit(0);

}


List<IChangeSetHandle> changeSetHandles = new ArrayList<IChangeSetHandle>();


for (ILink link: linkCollection) {

// Change set links should be item references

IChangeSetHandle changeSetHandle = (IChangeSetHandle) link.getSourceRef().resolve();


changeSetHandles.add(changeSetHandle);

}


@SuppressWarnings("unchecked")

List<IChangeSet> changeSets = itemManager.fetchCompleteItems(changeSetHandles, IItemManager.DEFAULT, new SysoutProgressMonitor());

Set<String> changedFilesAndFolders = new TreeSet<String>();

for (IChangeSet cs: changeSets) {

for (Object o: cs.changes()) {

IChange change = (IChange)o;


if (change.kind() != IChange.DELETE) {

IVersionableHandle after = change.afterState();

if(after!=null){

IVersionable afterVersionable = workspaceManager.versionableManager().fetchCompleteState(after, new SysoutProgressMonitor());

changedFilesAndFolders.add(afterVersionable.getName());

}

}


// If there was a rename then include the old name in the list as well

if (change.kind() == IChange.RENAME

|| change.kind() == IChange.DELETE) {

IVersionableHandle before = change.beforeState();

if(before!=null){

IVersionable beforeVersionable = workspaceManager.versionableManager().fetchCompleteState(before, new SysoutProgressMonitor());

changedFilesAndFolders.add(beforeVersionable.getName());

}

}


}

}


return changedFilesAndFolders;

}


catch( Exception e)

{


System.out.println(e);

return null;

}

}

}

