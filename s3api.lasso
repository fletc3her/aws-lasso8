<?lassoscript

	//
	// AWS S3 API Library
	//
	// Allows buckets and objects in S3 repositories to be manipulated. This is a
	// very partial implementation which only allows buckets and objects to be listed.
	//
	// Note: This library uses the S3 API commands which provide output in
	// machine friendly JSON format rather than the shell friendly S3 commands.
	//
	//	aws_region('us-west-2');
	//	aws_accesskeyid('MY_ACCESS_KEY');
	//	aws_secretaccesskey('MY_SECRET_KEY');
	//
	//	var('mybuckets' = s3api_list_buckets());
	//
	//	var('myobjects' = s3api_list_objects(-bucket='mybucket', -prefix='mydirectory/'));
	//
	// http://docs.aws.amazon.com/cli/latest/reference/s3api/index.html
	//
	// Copyright (c) 2015 by Fletcher Sandbeck
	// Released Under MIT License http://fletc3her.mit-license.org/
	//

	// s3api_list_buckets
	//
	// Lists the available buckets
	//
	//	http://docs.aws.amazon.com/cli/latest/reference/s3api/list-buckets.html
	define_tag('s3api_list_buckets', -namespace=namespace_global);
		return(aws('s3api', 'list-buckets', params));
	/define_tag;

	// s3api_list_objects
	//
	// Lists the available objects in a bucket with a specified prefix.
	//
	// -bucket = (string, required, also accepts a map with a "Name" entry)
	// -prefix = (string, optional, filters object to only those whose path begins with the prefix)
	// -starting_token = (string, optional, NextToken value from previous request, also accepts a map with a NextToken entry)
	// -max_items = (integer, maximum number of objects to return)
	//
	// http://docs.aws.amazon.com/cli/latest/reference/s3api/list-objects.html
	define_tag('s3api_list_objects', -required='bucket', -optional='prefix', -optional='starting_token', -optional='max_items', -namespace=namespace_global);
		iterate(array('bucket', 'delimiter', 'encoding_type', 'prefix', 'starting_token', 'page_size', 'max_items'), local('_p'));
			if(local_defined(#_p));
				params->removeall('-' + #_p) & removeall(local(#_p));
				// Extract Name or NextToken from Map
				(#_p == 'bucket' && local(#_p)->isa('map') && local(#_p) >> 'name') ? local(#_p = local(#_p)->find('name'));
				(#_p == 'starting_token' && local(#_p)->isa('map') && local(#_p) >> 'nexttoken') ? local(#_p = local(#_p)->find('nexttoken'));
				params->insert(('-' + #_p)=local(#_p));
			/if;
		/iterate;
		return(aws('s3api', 'list-objects', params));
	/define_tag;

	// s3api_key_array
	//
	// Utility function takes the output of s3api_list_objects and returns a simple array of object keys
	//
	define_tag('s3api_keyarray', -required='list', -namespace=namespace_global);
		local('out' = array);
		!#list->isa('map') ? return(@#out);
		#list !>> 'contents' ? return(@#out);
		iterate(#list->find('contents'), local('object'));
			#out->insert(#object->find('key'));
		/iterate;
		return(@#out);
	/define_tag;

?>
