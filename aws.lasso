﻿<?lassoscript

	//
	// AWS Utility Library
	//
	// This library defines the basic [aws] tag and helper tags for authentication
	// and settings.  All of the other AWS tags rely on this library.
	//
	// Copyright (c) 2014 by Fletcher Sandbeck
	// Released Under MIT License http://fletc3her.mit-license.org/
	//

	//
	// AWS Variables
	//
	// Most AWS calls require an access key ID and secret for access to the API.
	// Many calls also require that the endpoint for your region be set. These
	// tags allow the access key to be set once and used automatically by all
	// other tags.  See the documentation about individual AWS modules for
	// information about which variables are required for each call.
	//
	// Call with a value to set.  Call without a value to retrieve the set value.
	//
	// aws_accesskeyid(key)
	// aws_secretaccesskey(secret)
	// aws_region(region)
	// aws_path(path/to/aws) default '/usr/bin/aws'
	//
	define_tag('aws_accesskeyid', -optional='key', -namespace=namespace_global);
		local_defined('key') ? return(var('_aws_accesskeyid_' = #key));
		return(@$_aws_accesskeyid_);
	/define_tag;
	define_tag('aws_secretaccesskey', -optional='key', -namespace=namespace_global);
		local_defined('key') ? return(var('_aws_secretaccesskey_' = #key));
		return(@$_aws_secretaccesskey_);
	/define_tag;
	define_tag('aws_region', -optional='reg', -namespace=namespace_global);
		local_defined('reg') ? return(var('_aws_region_' = #reg));
		return(@$_aws_region_);
	/define_tag;
	define_tag('aws_path', -optional='path', -namespace=namespace_global);
		local_defined('path') ? return(var('_aws_path_' = #path));
		var('_aws_path_' = os_process('/usr/bin/which', array('aws'))->read);
		$_aws_path_ == '' ? $_aws_path_ = '/usr/bin/aws';
		return(@$_aws_path_);
	/define_tag;

	//
	// AWS Utilities
	//

	// aws_date()
	// Utility function returns properly formatted date string
	// Refreshes on each page load or use -refresh to force refresh
	// http://docs.aws.amazon.com/general/latest/gr/sigv4-date-handling.html
	define_tag('aws_date', -optional='refresh',-namespace=namespace_global);
		if(!var_defined('_aws_date_') || !var_defined('_aws_date_short_') || (local_defined('refresh') && (#refresh !== false)));
			local('date' = date(-gmt));
			var('_aws_date_' = #date->format('%QT%TZ'));
			var('_aws_date_short_' = #date->format('%Y%m%d'));
		/if;
		return(@$_aws_date_);
	/define_tag;

	// aws_encode(value)
	// Encodes values as JSON and escapes them properly as command line parameters.
	// http://docs.aws.amazon.com/cli/latest/userguide/cli-using-param.html
	// http://docs.aws.amazon.com/cli/latest/userguide/shorthand-syntax.html
		define_tag('aws_encode', -required='input', -namespace=namespace_global);
		if(#input->isa('array') || #input->isa('map'));
			local('simple'=true);
			local('output' = array);
			iterate(#input,local('i'));
				if(#i->isa('pair'));
					if(!#i->first->isa('string') || #i->first >> '"' || #i->second->isa('array') || #i->second->isa('map'));
						local('simple'=false);
						loop_abort;
					/if;
					local('s' = #i->second->isa('string') ? @#i->second | string(#i->second));
					#output->insert(#i->first + '=' + (#s >> '"' ? '"' + encode_sql(#s) + '"' | #s));
				else(#i->isa('array') || #i->isa('map'));
					local('simple'=false);
					loop_abort;
				else;
					local('s' = string(#i));
					#output->insert(#s >> '"' ? '"' + encode_sql(#s) + '"' | #s);
				/if;
			/iterate;
			#simple ? return(#output->join(','));
			return('"' + encode_sql(encode_json(#input)) + '"');
		else;
			local('s' = #input->isa('string') ? @#input | string(#input));
			return(#s >> '"' ? '"' + encode_sql(#s) + '"' | #s);
		/if;
	/define_tag;

	//
	// AWS Core
	//

	// aws(cmd, sub, params, options);
	// Note: Requires [os_process] permission
	// This tag calls the AWS CLI with the specified parameters.
	// http://docs.aws.amazon.com/cli/latest/userguide/command-structure.html
	// aws <command> <sub-command> [options and parameters]
	//
	// -params expects a map containing an entry for each parameter of the
	// sub-command. The name will have hyphens added automatically so can be
	// specified as a simple name, either "output" or "--output" works. The
	// value will be JSON encoded and can be a string, integer, map, or array as
	// needed. When a filename is requested it can be specified as file://path
	// or as a URL http://server/path.
	// Example [aws('elb','describe-load-balancers',-params=map('max-items'=5))]
	//
	// -options expects a map containing an entry for each option to the aws
	// call itself. These are all optional or can be set using the AWS Variables
	// tags above or the "set configure" command in the terminal.
	//  	access-key-id sets the access key on this call, defaults to aws_accesskeyid or value from "set configure"
	//  	secret-access-key sets the secret access key on this call, defaults to aws_secretaccesskey or value from "set configure"
	//  	region specifies the region to access, defaults to aws_region or value from "set configure"
	//  	output = [json,text,table] default json
	//  	debug turns on additional error output
	//  	no-verify-ssl turns off strict SSL certificate checking
	//  	no-paginate turns off default pagination
	//  	query specifies a JMESPath which will be applied to the results
	//		(see http://jmespath.readthedocs.org/en/latest/specification.html#identifiers)
	//  	profile specifies a specific profile to be used from "aws configure"
	//  	version returns the version and exits
	//  	color = [on,off,auto] default off
	define_tag('aws', -required='cmd', -required='sub', -namespace=namespace_global);

		local('aws_env' = array);
		local('aws_prm' = array);

		// Flatten Parameters
		local('_params' = array);
		iterate(params, local('p'));
			if(#p->isa('array') || #p->isa('map'));
				iterate(#p, local('q'));
					#_params->insert(#q);
				/iterate;
			else(#p->isa('pair') || (#p != #cmd && #p != #sub));
				#_params->insert(#p);
			/if;
		/iterate;

		// AWS Command
		#aws_prm->insert(#cmd);
		#aws_prm->insert(#sub);

		// Parameters
		iterate(#_params, local('p'));
			if(#p->isa('pair'));
				local('name' = string(#p->first)->removeleading('-')&replace('_','-')&);
				local('value' = #p->second);
				if(#name == 'access-key-id');
					#aws_env->insert('AWS_ACCESS_KEY_ID'=string(#value));
				else(#name == 'secret-access-key');
					#aws_env->insert('AWS_SECRET_ACCESS_KEY'=string(#value));
				else(#name == 'query' || #name == 'region' || #name == 'output' || #name == 'profile');
					#value == '' ? loop_continue; // Ignore Empty Parameters
					#aws_prm->insertfirst(aws_encode(#value)) & insertfirst('--' + #name); // backward for insertfirst
				else(#name == 'filters' && #value->isa('map'));
					#aws_prm->insert('--' + #name);
					iterate(#value, local('v'));
						#aws_prm->insert(aws_encode(array('Name'=#v->first,'Values'=#v->second)));
					/iterate;
				else(#value->isa('array'));
					#aws_prm->insert('--' + #name);
					iterate(#value, local('v'));
						#aws_prm->insert(aws_encode(#v));
					/iterate;
				else;
					#value == '' ? loop_continue; // Ignore Empty Parameters
					#aws_prm->insert('--' + #name) & insert(aws_encode(#value));
				/if;
			else(#p->isa('keyword'));
				#aws_prm->insert(string(#p)->removeleading('-')&replace('_','-')&);
			else;
				#aws_prm->insert(aws_encode(#p));
			/if;
		/iterate;

		// Defaults
		#aws_env !>> 'AWS_ACCESS_KEY_ID' && var_defined('_aws_accesskeyid_') && $_aws_accesskeyid_ != '' ? #aws_env->insert('AWS_ACCESS_KEY_ID'=aws_encode($_aws_accesskeyid_));
		#aws_env !>> 'AWS_SECRET_ACCESS_KEY' && var_defined('_aws_secretaccesskey_') && $_aws_secretaccesskey_ != '' ? #aws_env->insert('AWS_SECRET_ACCESS_KEY'=aws_encode($_aws_secretaccesskey_));
		#aws_prm !>> '--region' && (#cmd == 's3' || #cmd == 's3api') ? #aws_prm->insertfirst('us-east-1') & insertfirst('--region'); // backward for insertfirst
		#aws_prm !>> '--region' && var_defined('_aws_region_') && $_aws_region_ != '' ? #aws_prm->insertfirst(aws_encode($_aws_region_)) & insertfirst('--region'); // backward for insertfirst
		#aws_prm !>> '--output' ?  #aws_env->insertfirst('json') & insertfirst('--output'); // backward for insertfirst

		// AWS Path
		#aws_prm->insertfirst(aws_path);

		// Assemble curl command
		var('_aws_cmd_' = array);
		iterate(#aws_env, local('e'));
			!#e->isa('pair') ? loop_continue;
			$_aws_cmd_->insert(#e->first + '="' + encode_sql(#e->second) + '";');
			$_aws_cmd_->insert('export ' + #e->first + ';');
		/iterate;
		$_aws_cmd_->insert(#aws_prm->join(' ') + ';');

		// Call shell
		local('sh' = os_process('/bin/bash', array('-l', '-c', $_aws_cmd_->join(''))));
		var('_aws_raw_' = #sh->read);

		// Error processing
		if($_aws_raw_ == '');
			local('err' = #sh->readerror);
			fail_if(#err != '', -1, 'AWS Error: "' + #err + '"');
		/if;

		// Process output
		if(#cmd == 's3');
			return($_aws_raw_);
		/if;
		return(decode_json($_aws_raw_));
	/define_tag;

	//
	// Debugging
	//

	// aws_raw();
	// Returns the raw result
	define_tag('aws_raw', -namespace=namespace_global);
		return(var('_aws_raw_'));
	/define_tag;

	// aws_cmd();
	// Returns the raw command parameters
	define_tag('aws_cmd', -namespace=namespace_global);
		return(var('_aws_cmd_'));
	/define_tag;

?>
