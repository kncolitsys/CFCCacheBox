<!--- 

Notes:

Configuration parameters

AgentName
- The name of the CacheBoxAgent.

Context
- CLUSTER, SERVER or APPLICATION 
- Default: APPLICATION 

Evict
- Eviction policy for cache stored by this agent 
	- AUTO (default) 
	- PERF (AUTO w/ emphasis on speed) 
	- FRESH (AUTO w/ emphasis on content freshness) 
	- AGE:N - keep for N minutes 
	- IDLE:N - keep until idle for N minutes 
	- FIFO:N - First In First Out 
	- LRU:N - Least Recently Used 
	- LFU:N - Least Frequently Used 

AgentClass 
- A Class Path for the adapter to create a CacheBox Agent 
- allows the agent to be stored in the CacheBox directory or the Mach-II/caching/strategies/ directory 
- defaults to "cachebox.cacheboxagent" 

Sample Configuration: 
<property name="Caching" type="MachII.caching.CachingProperty">
      <parameters>
            <!-- Naming a default cache name is not required, but required if you do not want 
                 to specify the 'name' attribute in the cache command -->
            <parameter name="defaultCacheName" value="default" />
            <parameter name="default">
                  <struct>
                        <key name="type" value="MachII.caching.strategies.CacheBoxAdapter" />
                        <key name="agentname" value="MyModuleCache" />
                        <!-- optional parameters -->
                        <!-- <key name="context" value="application" /> -->
                        <!-- <key name="evict" value="idle:20" /> -->
                        <!-- <key name="agentclass" value="cachebox.cacheboxagent" /> -->
                  </struct>
            </parameter>
      </parameters>
</property>
--->

<cfcomponent
 	displayname="CacheBoxAdapter" 
	extends="MachII.caching.strategies.AbstractCacheStrategy" 
	output="false" 
	hint="A caching strategy which uses a CacheBox Agent.">

	<!---
	PROPERTIES
	--->
	<cfset variables.instance.strategyTypeName = "CacheBox" />
	<cfset variables.instance.AgentClass = "cachebox.cacheboxagent" />
	<cfset variables.instance.Context = "application" />
	<cfset variables.instance.Evict = "auto" />
	
	<!---
	INITIALIZATION / CONFIGURATION
	--->
	<cffunction name="configure" access="public" returntype="void" output="false"
		hint="Configures the strategy.">
		<cfset var cxt = "" />
		<cfset var evict = "" />
		
		<!--- Validate and set parameters --->
		<cfif not isParameterDefined("agentname")>
			<cfthrow type="MachII.caching.strategies.CacheBox"
					message="Agent Name Required."
					detail="You must supply an agentname parameter for CacheBox." />
		</cfif>
		<cfset instance.agentname = getParameter("agentname") />
		
		<cfif isParameterDefined("agentclass") and len(trim(getParameter("agentclass"))>
			<cfset instance.agentclass = getParameter("agentclass") />
		</cfif>
		
		<cfif isParameterDefined("evict") and len(trim(getParameter("evict"))>
			<cfset instance.evict = getParameter("evict") />
		</cfif>
		
		<cfif isParameterDefined("context")>
			<cfset cxt = getParameter("context") />
			<cfif NOT listfindnocase("cluster,server,application",cxt)>
				<cfthrow type="MachII.caching.strategies.CacheBox"
					message="Invalid Context of '#cxt#'."
					detail="Context must be CLUSTER, SERVER or APPLICATION." />
			<cfelse>			
				<cfset instance.context = cxt />
			</cfif>
		</cfif>
		
		<cfset instance.agent = CreateObject("component",instance.agentclass).init(
															agentname = instance.agentname,
															context = instance.context, 
															evict = instance.evict) />
	</cffunction>
	
	<!---
	PUBLIC FUNCTIONS
	--->
	<cffunction name="put" access="public" returntype="struct" output="false"
		hint="Puts data into the cache by key.">
		<cfargument name="key" type="string" required="true" />
		<cfargument name="data" type="any" required="true" />
		
		<cfreturn instance.agent.store(key,data) />
	</cffunction>
	
	<cffunction name="get" access="public" returntype="struct" output="false" 
		hint="Gets data from the cache by key. Returns null if the key is not in the cache.">
		<cfargument name="key" type="string" required="true" />
		
		<cfreturn instance.agent.fetch(key) />
	</cffunction>
	
	<cffunction name="flush" access="public" returntype="void" output="false"
		hint="Flushes the entire cache.">
		
		<cfset instance.agent.reset() />
	</cffunction>
	
	<cffunction name="remove" access="public" returntype="void" output="false"
		hint="Removes data from the cache by key.">
		<cfargument name="key" type="string" required="true"
			hint="The key does not need to be hashed." />
		<cfset instance.agent.delete(key) />
	</cffunction>
	
	<cffunction name="reap" access="public" returntype="void" output="false" 
		hint="this method is ignored because CacheBox reaps with a scheduled task">
	</cffunction>
	
	<!--- 
	PUBLIC FUNCTIONS - UTILS
	--->
	<cffunction name="getConfigurationData" access="public" returntype="struct" output="false"
		hint="Gets pretty configuration data for this caching strategy.">
		
		<cfset var data = StructNew() />
		
		<cfset data.agentName = instance.agentName />
		<cfset data.context = instance.context />
		<cfset data.appliedcontext = instance.agent.getAppliedContext() />
		<cfset data.evict = instance.evict />
		<cfset data.appliedevictpolicy = instance.agent.getAppliedEvictPolicy() />
		<cfset data["Cache Enabled"] = YesNoFormat(isCacheEnabled()) />
		
		<cfreturn data />
	</cffunction>
		
</cfcomponent>