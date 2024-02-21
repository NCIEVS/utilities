/**
 * 
 */
package org.example;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import org.eclipse.rdf4j.RDF4JException;
import org.eclipse.rdf4j.query.Binding;
import org.eclipse.rdf4j.query.BindingSet;
import org.eclipse.rdf4j.query.BooleanQuery;
import org.eclipse.rdf4j.query.Query;
import org.eclipse.rdf4j.query.QueryEvaluationException;
import org.eclipse.rdf4j.query.QueryLanguage;
import org.eclipse.rdf4j.query.QueryResults;
import org.eclipse.rdf4j.query.TupleQuery;
import org.eclipse.rdf4j.query.TupleQueryResult;
import org.eclipse.rdf4j.repository.Repository;
import org.eclipse.rdf4j.repository.sparql.SPARQLRepository;


/**
 * @author bitdiddle
 *
 */
public class TripleStore {
	
	private String sparqlEndpoint = "http://localhost:8890/sparql";
	private Repository repo = null;
	
	private String prefix = "prefix ncit: <http://ncicb.nci.nih.gov/xml/owl/EVS/Thesaurus.owl#> "
			+ "select distinct ?subclass ?label str(if(bound(?exists), 1, 0) as ?hasChildren)" 
			+ "from <http://ncicb.nci.nih.gov/xml/owl/EVS/Thesaurus.owl/Small2> "
			+ "where { "
			+ "  values ?superclass { ";
	
	
  
    private String suffix =
			" }  ?subclass (rdfs:subClassOf|(owl:equivalentClass/owl:intersectionOf/rdf:rest*/rdf:first) ) ?superclass ; "
			+ "      rdfs:label ?label . "
			+ "  optional { ?exists (rdfs:subClassOf|(owl:equivalentClass/owl:intersectionOf/rdf:rest*/rdf:first) ) ?subclass . }    "
			+ "} order by ?label";
	
	
	

	public TripleStore(String iri) {
		
		sparqlEndpoint = iri;
		
		repo = new SPARQLRepository(sparqlEndpoint);
		
		repo.initialize();
		
	}
	
	public List<String[]> runQuery(String code) {
		
		String qs = this.prefix +
				"ncit:" + code +
				this.suffix;
		
		
		Query query = repo.getConnection().prepareQuery(QueryLanguage.SPARQL, qs);
		
		ArrayList<String[]> res = new ArrayList<String[]>();
		if (query instanceof TupleQuery) {
			
			List<BindingSet> resultList;
			try (TupleQueryResult result = ((TupleQuery) query).evaluate()) {
			   resultList = QueryResults.asList(result);
			   
			   
			   for (BindingSet bs: resultList) {
				    //Set<String> names = bs.getBindingNames();
					String[] tmp = new String[3];
					int i = 0;
					Iterator<Binding> it = bs.iterator();
					while (it.hasNext()) {
						Binding b = it.next();
						tmp[i++] = b.getValue().stringValue();

						//System.out.println((b.getName() + " " + b.getValue()));
					}
					res.add(tmp);
			   }
			   return res;
					
					
					
					
				}
			   
			
			catch (RDF4JException e) {
				   // handle exception. This catch-clause is
				   // optional since RDF4JException is an unchecked exception
				}
			
			
		} else if (query instanceof BooleanQuery) {
			if (((BooleanQuery) query).evaluate()) {
				System.out.println("TRUE");
			}
			System.out.println("FALSE");
		}
		return res;
		
		
		
		}
		
		
		
		
		
		
		

	}
	


