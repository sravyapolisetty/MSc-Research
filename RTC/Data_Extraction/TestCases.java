
		/* 
		 *Sravya Polisetty March 21st 2017*
		 *Last Edited: April 15th 2017
		 *This code is used to fetch all the Test Cases from RMP project.
		 *Can be modified to get data for a particular release
		 *Input: repo url, username, password,Project Area Name
		 *Output: TC.xml,Comments.xml
		 */

		import java.io.IOException;
		import java.net.URI;
		import java.util.ArrayList;
		import java.util.List;
		import java.io.File;
		import java.io.FileNotFoundException;
		import javax.xml.parsers.DocumentBuilder;
		import javax.xml.parsers.DocumentBuilderFactory;
		import javax.xml.transform.Transformer;
		import javax.xml.transform.TransformerFactory;
		import javax.xml.transform.dom.DOMSource;
		import javax.xml.transform.stream.StreamResult;
		

		import org.w3c.dom.Attr;
		import org.w3c.dom.Document;
		import org.w3c.dom.Element;
		import org.eclipse.core.runtime.IProgressMonitor;
		import org.apache.commons.lang3.StringEscapeUtils;

		
		import com.ibm.team.repository.client.IItemManager;
		import com.ibm.team.repository.client.ITeamRepository;
		import com.ibm.team.repository.client.TeamPlatform;
		import com.ibm.team.repository.client.ITeamRepository.ILoginHandler;
		import com.ibm.team.repository.client.ITeamRepository.ILoginHandler.ILoginInfo;
		import com.ibm.team.repository.common.IContributor;
		import com.ibm.team.repository.common.IContributorHandle;
		import com.ibm.team.repository.common.ItemNotFoundException;
		import com.ibm.team.repository.common.TeamRepositoryException;
		import com.ibm.team.repository.common.transport.ConnectionException;
		import com.ibm.team.repository.common.util.NLS;
		import com.ibm.team.links.client.ILinkManager;
		import com.ibm.team.links.common.IItemReference;
		import com.ibm.team.links.common.ILink;
		import com.ibm.team.links.common.ILinkCollection;
		import com.ibm.team.process.client.IProcessClientService;
		//import com.ibm.team.process.common.IDevelopmentLine;
		//import com.ibm.team.process.common.IDevelopmentLineHandle;
		import com.ibm.team.process.common.IIteration;
		//import com.ibm.team.process.common.IIterationHandle;
		import com.ibm.team.process.common.IProjectArea;
		import com.ibm.team.process.common.IProjectAreaHandle;
        //import com.ibm.team.process.internal.common.DevelopmentLine;
		//import com.ibm.team.workitem.api.common.WorkItemAttributes;
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
		//import com.ibm.team.workitem.common.model.IAttribute;
		import com.ibm.team.workitem.common.model.IComment;
		import com.ibm.team.workitem.common.model.IComments;
		import com.ibm.team.workitem.common.model.IWorkItem;
		import com.ibm.team.workitem.common.model.ItemProfile;
		import com.ibm.team.workitem.common.model.WorkItemLinkTypes;
		import com.ibm.team.workitem.common.query.IQueryResult;
		import com.ibm.team.workitem.common.query.IResolvedResult;
		import com.ibm.team.workitem.common.text.WorkItemTextUtilities;

		public class TestCases {
			
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
				String workItemType="com.ibm.rm.workitem.storyverification";//Test Case
				//String plannedFor=args[4];
				
				System.out.println("Project Area : " + projectAreaName);
				//System.out.println("Planned For Release : " + plannedFor);
				System.out.println("Work Item Type : " +workItemType);
				
				try {
					TeamPlatform.startup();
					ITeamRepository repository= login(repositoryURI, userId, password);
					//IQueryResult<IResolvedResult<IWorkItem>> result= getResult(repository, projectAreaName,workItemType,plannedFor);
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

			
			private static void printResult(IQueryResult<IResolvedResult<IWorkItem>> result,ITeamRepository repo) throws TeamRepositoryException, FileNotFoundException {
				
				try
				{
				
					DocumentBuilderFactory docFactory = DocumentBuilderFactory.newInstance();
					DocumentBuilder docBuilder = docFactory.newDocumentBuilder();
					

					// root elements
					Document doc = docBuilder.newDocument();
					Element rootElement = doc.createElement("TC");
					doc.appendChild(rootElement);
					
					Document docComments=docBuilder.newDocument();
					Element rootCommElement = docComments.createElement("CT");
					docComments.appendChild(rootCommElement);
					
					System.out.println("-------------------------------------------------------------------------------");
					System.out.println(NLS.bind("WorkItem count: {0}", result.getResultSize(null).getTotal()));
					System.out.println("-------------------------------------------------------------------------------");
					System.out.println("Writing to output file in XML");
					while (result.hasNext(null)) {
					
					IResolvedResult<IWorkItem> resolved= result.next(null);
					String testCaseId=WorkItemTextUtilities.getWorkItemId(resolved.getItem());
					String testCaseSummary= WorkItemTextUtilities.getWorkItemText(resolved.getItem());
					String testCaseDesc=StringEscapeUtils.escapeXml11
							(resolved.getItem().getHTMLDescription().getPlainText());
					String parentDesc=getParent(resolved.getItem(),repo);
					String plannedFor="UnAsssigned";
					
					int intTestCaseId=Integer.parseInt(testCaseId);
					
					IWorkItemClient workItemClient = (IWorkItemClient) repo.getClientLibrary(IWorkItemClient.class);
					IWorkItem workItem = workItemClient.findWorkItemById(intTestCaseId, IWorkItem.FULL_PROFILE, new SysoutProgressMonitor());
					IAuditableClient auditableClient= (IAuditableClient) repo.getClientLibrary(IAuditableClient.class);
					
					if(workItem.getTarget()!=null){
				    IIteration iteration = auditableClient.resolveAuditable(workItem.getTarget(),ItemProfile.ITERATION_DEFAULT, null); 
					
				    plannedFor=iteration.getName();
				    
					}
					
					IComments comments = resolved.getItem().getComments();
					IComment[] theComments = comments.getContents();
					List<String> commentText = new ArrayList<String>(theComments.length);
					List<String> commentDate=new ArrayList<String>(theComments.length);
					List<String> commentCreator=new ArrayList<String>(theComments.length);
					
					
					for (IComment aComment : theComments) {
						commentText.add(StringEscapeUtils.escapeXml11
								(aComment.getHTMLContent().getPlainText()));
						commentDate.add(aComment.getCreationDate().toString());
						commentCreator.add(calculateContributorAsString(aComment.getCreator(),repo,null));
						
					}
					

					Element testcase=doc.createElement("testcase");
					rootElement.appendChild(testcase);
					
					Attr attr = doc.createAttribute("id");
					attr.setValue(testCaseId);
					testcase.setAttributeNode(attr);
					
					Attr attrRelease=doc.createAttribute("plannedfor");
					attrRelease.setValue(plannedFor);
					testcase.setAttributeNode(attrRelease);
					
					Element summary = doc.createElement("summary");
					summary.appendChild(doc.createTextNode(testCaseSummary));
					testcase.appendChild(summary);
					
					Element description=doc.createElement("description");
					description.appendChild(doc.createTextNode(testCaseDesc));
					testcase.appendChild(description);
										
					
					
					for(int i=0;i<theComments.length;i++){
						
						Element commentNode=docComments.createElement("comment");
						rootCommElement.appendChild(commentNode);
						
						Attr attrWI=docComments.createAttribute("workItem");
						attrWI.setValue(testCaseId);
						commentNode.setAttributeNode(attrWI);
						
						Attr attrTxt=docComments.createAttribute("commentText");
						attrTxt.setValue(commentText.get(i));
						commentNode.setAttributeNode(attrTxt);
						
						Attr attrDate=docComments.createAttribute("creationDate");
						attrDate.setValue(commentDate.get(i));
						commentNode.setAttributeNode(attrDate);
						
						Attr attrCreator=docComments.createAttribute("creator");
						attrCreator.setValue(commentCreator.get(i));
						commentNode.setAttributeNode(attrCreator);
						
					}
					
					
					Element parent=doc.createElement("parent");
					parent.appendChild(doc.createTextNode(parentDesc));
					testcase.appendChild(parent);
				}
			
					
					TransformerFactory transformerFactory1 = TransformerFactory.newInstance();
					TransformerFactory transforemerFactory2=TransformerFactory.newInstance();
					
					Transformer transformer1 = transformerFactory1.newTransformer();
					Transformer transformer2=transforemerFactory2.newTransformer();
					
					DOMSource source = new DOMSource(doc);
					DOMSource sourceComments = new DOMSource(docComments);
					
					StreamResult output = new StreamResult(new File("C:\\TC.xml"));
					StreamResult outputComments = new StreamResult(new File("C:\\Comments.xml"));
					
					transformer1.transform(source, output);
					transformer2.transform(sourceComments, outputComments);

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
				//IAuditableCommon auditableCommon = (IAuditableCommon) auditableClient.getTeamRepository().getClientLibrary(IAuditableCommon.class); 
				URI uri= URI.create(projectAreaName.replaceAll(" ", "%20"));
				IProjectArea projectArea= (IProjectArea) processClient.findProcessArea(uri, null, null);
				if (projectArea == null) {
					throw new ItemNotFoundException(NLS.bind("Project area {0} not found", projectAreaName));
				}
				
				//IProjectAreaHandle iProjectAreaHandle = projectArea.getProjectArea();
				
				//IIterationHandle iterationHandleForRev = findIteration(iProjectAreaHandle,plannedFor,repository,auditableCommon);
				
				IQueryableAttribute projectAreaAttribute= findAttribute(projectArea, auditableClient, IWorkItem.PROJECT_AREA_PROPERTY, null);
				
				IQueryableAttribute workItemTypeAttribute= findAttribute(projectArea, auditableClient, IWorkItem.TYPE_PROPERTY, null);
				
				//IQueryableAttribute plannedForAttribute=findAttribute(projectArea,auditableClient, IWorkItem.TARGET_PROPERTY, null);
				
				
				AttributeExpression projectAreaExpression= new AttributeExpression(projectAreaAttribute, AttributeOperation.EQUALS, projectArea);
				
				AttributeExpression workItemTypeExpression=new AttributeExpression(workItemTypeAttribute,AttributeOperation.EQUALS,workItemType);
				
				//AttributeExpression plannedForAttributeExpression=new AttributeExpression(plannedForAttribute,AttributeOperation.EQUALS,iterationHandleForRev);
				
				Term term= new Term(Operator.AND);
				term.add(projectAreaExpression);
				term.add(workItemTypeExpression);
				//term.add(plannedForAttributeExpression);
				
				IQueryResult<IResolvedResult<IWorkItem>> queryResults=queryClient.getResolvedExpressionResults(projectArea, term, IWorkItem.FULL_PROFILE);
				queryResults.setLimit(Integer.MAX_VALUE);
				return queryResults;
				
				
			}
			
			//To get release-wise data
			
			/*private static IIteration findIteration(IProjectAreaHandle iProjectAreaHandle, String plannedFor,ITeamRepository repo,IAuditableCommon auditableCommon) 
		            throws TeamRepositoryException { 
		        IProjectArea projectArea = (IProjectArea) repo.itemManager().fetchCompleteItem( 
		                iProjectAreaHandle, IItemManager.REFRESH, null); 
		        return findIterationInAllDevelopmentLines(projectArea,auditableCommon,plannedFor); 
		    } 
			
			
			
			private static IIteration findIterationInAllDevelopmentLines(IProjectArea projectArea,IAuditableCommon auditableCommon, String plannedFor) 
		            throws TeamRepositoryException { 
		        IDevelopmentLineHandle[] developmentLineHandles = projectArea.getDevelopmentLines(); 
		        for (IDevelopmentLineHandle developmentLineHandle : developmentLineHandles) { 
		            IDevelopmentLine developmentLine = auditableCommon.resolveAuditable( 
		                    developmentLineHandle, ItemProfile.DEVELOPMENT_LINE_DEFAULT, null); 

		            IIteration targetIteration = findIteration(developmentLine.getIterations(), plannedFor,auditableCommon); 
		            if (targetIteration != null) { 
		                return targetIteration; 
		            } 
		        } 
		        return null; 
			}
		        
		        
			
		        private static IIteration findIteration(IIterationHandle[] iterations, String plannedFor,IAuditableCommon auditableCommon) 
		                throws TeamRepositoryException { 

		            for (IIterationHandle iIterationHandle : iterations) { 

		                IIteration iteration = auditableCommon.resolveAuditable(iIterationHandle, 
		                        ItemProfile.ITERATION_DEFAULT, null); 
		                String compare = iteration.getName(); 
		                // base case 1: found iteration 
		                if (plannedFor.equals(compare)) { 
		                    return iteration; 
		                } 

		                // recursive step: look in children iterations 
		                IIterationHandle[] iterationHandlers = iteration.getChildren(); 
		                if (iterationHandlers != null) { 

		                    IIteration found = findIteration(iteration.getChildren(), plannedFor,auditableCommon); 
		                    if (found != null) { 
		                        return found; 
		                    } 
		                } 
		            } 

		            // no iteration found 
		            return null; 
		        } 
*/		    

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
			
			private static String getParent(IWorkItem workItem, ITeamRepository repo)
			{
				String parent="";
				try
				{
				ILinkManager linkManager = (ILinkManager) repo.getClientLibrary(ILinkManager.class);
				IItemReference workItemReference = linkManager.referenceFactory().createReferenceToItem(workItem);
				ILinkCollection linkCollection = linkManager.findLinksBySource(WorkItemLinkTypes.PARENT_WORK_ITEM, workItemReference, new SysoutProgressMonitor()).getAllLinksFromHereOn();
				
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
			
			private static String calculateContributorAsString(Object value,ITeamRepository repo,IProgressMonitor monitor)
					throws TeamRepositoryException {
				
				try{
				
					IContributor contributor = (IContributor)repo.itemManager().fetchCompleteItem(
									(IContributorHandle) value, IItemManager.DEFAULT,monitor);
					return contributor.getName();
				}
				catch(TeamRepositoryException e)
				{
					return e.toString();
				}
				
				
			}

		}
	
