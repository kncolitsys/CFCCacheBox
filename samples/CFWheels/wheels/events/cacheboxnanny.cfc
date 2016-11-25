﻿<cfcomponent displayname="CacheBoxNanny" output="false" 
hint="I provide additional per-item cache expiration for CacheBox at the client, similar to ColdFusion query caching features">
	<cfset instance = structNew() />
	<cfset instance.created = now() />
	<cfset instance.rules = structNew() />
	
	<cffunction name="init" access="public" output="false">
		<cfargument name="Agent" type="any" required="true" hint="a CacheBox agent around which the Nanny is wrapped" />
		<cfset structAppend(instance,arguments,true) />
		<cfreturn this />
	</cffunction>
	
	<cffunction name="getAgent" access="public" output="false" hint="I return the CacheBox agent aroudn which te Nanny is wrapped">
		<cfreturn instance.agent />
	</cffunction>
	
	<cffunction name="debug" access="public" output="true">
		<cfdump var="#variables.instance#" />
	</cffunction>
	
	<cffunction name="isCachedAfter" access="private" output="false" returntype="boolean" 
	hint="I check the birthdate of a content item for eviction based on a cachedafter date">
		<cfargument name="birth" type="string" required="true" hint="the time of the content item's creation" />
		<cfargument name="after" type="string" required="true" hint="the time after which the content is cached" />
		
		<!--- if no cachedafter date is supplied, the test passes by default--->
		<cfif not isDate(after)><cfreturn true /></cfif>
		
		<!--- otherwise apply the test --->
		<cfreturn iif(arguments.birth lte arguments.after,true,false) />
	</cffunction>
	
	<cffunction name="isCachedWithin" access="private" output="false" returntype="boolean" 
	hint="I check the birthdate of a content item for eviction based on a cachedwithin number">
		<cfargument name="birth" type="string" required="true" hint="the time of the content item's creation" />
		<cfargument name="within" type="string" required="true" hint="the interval within which the content is cached" />
		
		<!--- if no cachedwhithin interval was given, the test passes by default --->
		<cfif val(within) eq 0><cfreturn true /></cfif>
		
		<!--- otherwise apply the test --->
		<cfreturn iif(birth gte dateadd("s",-int(86400*arguments.within),now()),true,false) />
	</cffunction>
	
	<cffunction name="fetch" access="public" output="false" returntype="struct">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="cachedafter" type="string" required="false" default="" />
		<cfset var agent = getAgent() />
		<cfset var result = structNew() />
		<cfset var evict = iif(structKeyExists(instance.rules,cachename),"instance.rules[cachename]","structNew()") />
		
		<cfparam name="evict.cachedwithin" type="numeric" default="0" />
		<cfparam name="evict.birth" type="date" default="#now()#" />
		
		<cfif not isCachedAfter(evict.birth,arguments.cachedafter) or not isCachedWithin(evict.birth,evict.cachedwithin)>
			<!--- the content is not fresh enough based on the cachedafter or cachedwithin arguments, return a standard cache miss status --->
			<cfset result.content = "" />
			<cfset result.status = 1 />
			<cfreturn result />
		</cfif>
		
		<cfreturn agent.fetch(cachename) />
	</cffunction>
	
	<cffunction name="store" access="public" output="false" returntype="struct">
		<cfargument name="cachename" type="string" required="true" />
		<cfargument name="content" type="any" required="true" />
		<cfargument name="cachedwithin" type="numeric" required="false" default="0" />
		
		<cfset instance.rules[arguments.cachename] = { cachedwithin=arguments.cachedwithin, birth=now() } />
		
		<cfreturn getAgent().store(cachename,content) />
	</cffunction>
	
	<cffunction name="delete" access="public" output="false" hint="removes one or more records from the agent's cache - a wild-card (%) at the end of the cache name can be used to remove multiple related records">
		<cfargument name="cachename" type="string" required="true" />
		<!--- throw away our expiration rules (this doesn't work with wildcards) --->
		<cfset structDelete(instance.rules,cachename) />
		<!--- remove the content from cache --->
		<cfset getAgent().delete(cachename) />
	</cffunction>
	
	<cffunction name="expire" access="public" output="false" hint="removes one or more records from the agent's cache - a wild-card (%) at the end of the cache name can be used to remove multiple related records">
		<cfargument name="cachename" type="string" required="false" default="%" />
		<!--- throw away our expiration rules (this doesn't work with partial wildcards) --->
		<cfif cachename is "%">
			<cfset structClear(instance.rules) />
		<cfelse>
			<cfset structDelete(instance.rules,cachename) />
		</cfif>
		<!--- remove the content from cache --->
		<cfset getAgent().expire(cachename) />
	</cffunction>
	
	<cffunction name="reset" access="public" output="false" hint="removes all content from cache for the wrapped agent">
		<!--- throw away our expiration rules --->
		<cfset instance.rules = structNew() />
		<!--- remove all agent content from cache --->
		<cfset getAgent().reset() />
	</cffunction>
	
	<cffunction name="getSize" access="public" output="false">
		<cfreturn getAgent().getSize() />
	</cffunction>
	
</cfcomponent>