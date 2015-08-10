<?lassoscript

	//
	// AWS Simple Queue Service (SQS) Library
	//
	// Allows messages to be sent and retrieved from flexible distributed queues.
	//
	//
	//	aws_region('us-west-2');
	//	aws_accesskeyid('MY_ACCESS_KEY');
	//	aws_secretaccesskey('MY_SECRET_KEY');
	//
	//	var('myqueue' = sqs_create_queue('myqueue', -attributes=map('DelaySeconds'=30)));
	//
	//	sqs_send_message($myqueue, 'Message sent at: ' + date->format('%Q %T'));
	//
	//	var('messages' = sqs_receive_message($myqueue, -max_number_of_messages=10));
	//	if($messages->size > 0);
	//		iterate($messages->find('messages'), var('message'));
	//			var('body' = $message->find('body'));
	//			... process body ...
	//			sqs_delete_message($queue, $message);
	//		/iterate;
	//	/if;
	//
	//	sqs_delete_queue(sqs_get_queue_url('myqueue'));
	//
	//
	// http://docs.aws.amazon.com/cli/latest/reference/sqs/index.html
	//
	// Copyright (c) 2014 by Fletcher Sandbeck
	// Released Under MIT License http://fletc3her.mit-license.org/
	//

	// sqs_add_permission
	//
	// Adds permission for another AWS user to access a queue.  Possible actions
	// include *, send-message, receive-message, delete-message,
	// change-message-visibility, get-queue-attributes, get-queue-url.
	//
	// -queue_url = (url, required, also accepts a map with a "QueueURL" entry)
	// -label = (string, required, your name for this permission entry)
	// -aws_account_ids = (array of strings, required)
	// -actions = (array of strings, required)
	//
	// http://docs.aws.amazon.com/cli/latest/reference/sqs/add_permission.html
	define_tag('sqs_add_permission', -required='queue_url', -required='label', -required='aws_account_ids', -required='actions', -namespace=namespace_global);
		iterate(array('queue_url', 'label', 'aws_account_ids', 'actions'), local('_p'));
			if(local_defined(#_p));
				params->removeall('-' + #_p) & removeall(local(#_p));
				// Extract Queue URL From Map
				(#_p == 'queue_url' && local(#_p)->isa('map') && local(#_p) >> 'queueurl') ? local(#_p = local(#_p)->find('queueurl'));
				params->insert(('-' + #_p)=local(#_p));
			/if;
		/iterate;
		return(aws('sqs', 'add-permission', params));
	/define_tag;

	// sqs_change_message_visibility
	//
	// Sets the visibility timeout for a message.  When you receive a message it
	// is automatically made invisible so other queue readers don't receive it
	// until you are done.  By default the timeout is 30 seconds.  You can use
	// this tag to make the timeout longer if necessary or to reset the timeout
	// to 0 if you want to punt on the message.
	//
	// -queue_url = (url, required, also accepts a map with a "QueueURL" entry)
	// -receipt-handle = (handle, required, also accepts a map with a "ReceiptHandle" entry)
	// -visibility_timeout = (integer seconds, required)
	//
	// http://docs.aws.amazon.com/cli/latest/reference/sqs/change_message_visibility.html
	define_tag('sqs_change_message_visibility', -namespace=namespace_global);
		iterate(array('queue_url', 'receipt_handle', 'visibility_timeout'), local('_p'));
			if(local_defined(#_p));
				params->removeall('-' + #_p) & removeall(local(#_p));
				// Extract Queue URL From Map
				(#_p == 'queue_url' && local(#_p)->isa('map') && local(#_p) >> 'queueurl') ? local(#_p = local(#_p)->find('queueurl'));
				// Extract Receipt Handle From Map
				(#_p == 'receipt_handle' && local(#_p)->isa('map') && local(#_p) >> 'receipthandle') ? local(#_p = local(#_p)->find('receipthandle'));
				params->insert(('-' + #_p)=local(#_p));
			/if;
		/iterate;
		return(aws('sqs', 'change-message-visibility', params));
	/define_tag;

	// sqs_change_message_visibility_batch
	//
	// The batch entries are specified as an array of maps each containing: "ID"
	// your identifier passed back in results, "ReceiptHandle" identifying one
	// message, and "VisibilityTimeout" the new timeout for the message.
	//
	// Note: Entries map names are case sensitive.
	//
	//
	// -queue_url = (url, required, also accepts a map with a "QueueURL" entry)
	// -entries = (map)
	//
	// http://docs.aws.amazon.com/cli/latest/reference/sqs/change_message_visibility_batch.html
	define_tag('sqs_change_message_visibility_batch', -required='queue_url', -required='entries', -namespace=namespace_global);
		iterate(array('queue_url', 'entries'), local('_p'));
			if(local_defined(#_p));
				params->removeall('-' + #_p) & removeall(local(#_p));
				// Extract Queue URL From Map
				(#_p == 'queue_url' && local(#_p)->isa('map') && local(#_p) >> 'queueurl') ? local(#_p = local(#_p)->find('queueurl'));
				params->insert(('-' + #_p)=local(#_p));
			/if;
		/iterate;
		return(aws('sqs', 'change-message-visbiility-batch', params));
	/define_tag;

	// sqs_create_queue
	//
	// Creates a queue with the specified -queue_name and optional -attributes.
	// If a queue with that name already exists it returns the queue URL.
	// Returns a map containing the "QueueUrl".
	//
	// -queue_name = 'string' (name of the queue, required)
	// -attributes = map (map of parameters for the queue, see docs, optional)
	//
	// http://docs.aws.amazon.com/cli/latest/reference/sqs/create-queue.html
	define_tag('sqs_create_queue', -required='queue_name', -optional='attributes', -namespace=namespace_global);
		iterate(array('queue_name', 'attributes'), local('_p'));
			local_defined(#_p) ? params->removeall('-' + #_p) & removeall(local(#_p)) & insert(('-' + #_p)=local(#_p));
		/iterate;
		return(aws('sqs', 'create-queue', params));
	/define_tag;

	// sqs_delete_message
	//
	// Deletes a message from the queue.  This signifies that you have
	// successfully processed the message.  Note that you must delete every
	// message you receive or it will continue to be sent to other queue
	// listeners.
	//
	// -queue_url = (url, required, also accepts a map with a "QueueURL" entry)
	// -receipt-handle = (handle, required, also accepts a map with a "ReceiptHandle" entry)
	//
	// http://docs.aws.amazon.com/cli/latest/reference/sqs/delete_message.html
	define_tag('sqs_delete_message', -required='queue_url', -required='receipt_handle', -namespace=namespace_global);
		iterate(array('queue_url', 'receipt_handle'), local('_p'));
			if(local_defined(#_p));
				params->removeall('-' + #_p) & removeall(local(#_p));
				// Extract Queue URL From Map
				(#_p == 'queue_url' && local(#_p)->isa('map') && local(#_p) >> 'queueurl') ? local(#_p = local(#_p)->find('queueurl'));
				// Extract Receipt Handle From Map
				(#_p == 'receipt_handle' && local(#_p)->isa('map') && local(#_p) >> 'receipthandle') ? local(#_p = local(#_p)->find('receipthandle'));
				params->insert(('-' + #_p)=local(#_p));
			/if;
		/iterate;
		return(aws('sqs', 'delete-message', params));
	/define_tag;

	// sqs_delete_message_batch
	//
	// The batch entries are specified as an array of maps each containing: "ID"
	// your identifier passed back in results and "ReceiptHandle" identifying
	// one message.
	//
	// Note: Entries map names are case sensitive.
	//
	//
	// -queue_url = (url, required, also accepts a map with a "QueueURL" entry)
	// -entries = (map)
	//
	// http://docs.aws.amazon.com/cli/latest/reference/sqs/delete_message_batch.html
	define_tag('sqs_delete_message_batch', -required='queue_url', -required='entries', -namespace=namespace_global);
		iterate(array('queue_url', 'entries'), local('_p'));
			if(local_defined(#_p));
				params->removeall('-' + #_p) & removeall(local(#_p));
				// Extract Queue URL From Map
				(#_p == 'queue_url' && local(#_p)->isa('map') && local(#_p) >> 'queueurl') ? local(#_p = local(#_p)->find('queueurl'));
				params->insert(('-' + #_p)=local(#_p));
			/if;
		/iterate;
		return(aws('sqs', 'delete-message-batch', params));
	/define_tag;

	// sqs_delete_queue
	//
	// Deletes the specified queue.
	//
	// -queue_url = (url, required, also accepts a map with a "QueueURL" entry)
	//
	// http://docs.aws.amazon.com/cli/latest/reference/sqs/delete_queue.html
	define_tag('sqs_delete_queue', -required='queue_url', -namespace=namespace_global);
		iterate(array('queue_url'), local('_p'));
			if(local_defined(#_p));
				params->removeall('-' + #_p) & removeall(local(#_p));
				// Extract Queue URL From Map
				(#_p == 'queue_url' && local(#_p)->isa('map') && local(#_p) >> 'queueurl') ? local(#_p = local(#_p)->find('queueurl'));
				params->insert(('-' + #_p)=local(#_p));
			/if;
		/iterate;
		return(aws('sqs', 'delete-queue', params));
	/define_tag;

	// sqs_get_queue_attributes
	//
	// Gets a map of attributes for the queue including estimates of how many
	// messages are waiting and the default timeouts for the queue.  The
	// following attributes are available: All, Policy, VisibilityTimeout,
	// MaximumMessageSize, MessageRetentionPeriod, ApproximateNumberOfMessages,
	// ApproximateNumberOfMessagesNotVisible, CreatedTimestamp,
	// LastModifiedTimestamp, QueueArn, ApproximateNumberOfMessagesDelayed,
	// DelaySeconds, ReceiveMessageWaitTimeSeconds, RedrivePolicy.
	//
	// Note: Attribute names are case sensitive.
	//
	// -queue_url = (url, required, also accepts a map with a "QueueURL" entry)
	// -attribute_namess = (array of strings, optional, defaults to "All")
	//
	// http://docs.aws.amazon.com/cli/latest/reference/sqs/get_queue_attributes.html
	define_tag('sqs_get_queue_attributes', -required='queue_url', -optional='attribute_names', -namespace=namespace_global);
		iterate(array('queue_url', 'attribute_names'), local('_p'));
			if(local_defined(#_p));
				params->removeall('-' + #_p) & removeall(local(#_p));
				// Extract Queue URL From Map
				(#_p == 'queue_url' && local(#_p)->isa('map') && local(#_p) >> 'queueurl') ? local(#_p = local(#_p)->find('queueurl'));
				params->insert(('-' + #_p)=local(#_p));
			/if;
		/iterate;
		params !>> -attribute_names ? params->insert(-attribute_names='All');
		return(aws('sqs', 'get-queue-attributes', params));
	/define_tag;

	// sqs_get_queue_url
	//
	// Returns the URL for a named queue. Can be used to get a queue URL for
	// another account by specifying an AWS account ID.
	//
	// -queue_name = (string, required)
	// -queue_owner_aws_account_id = (string, optional, defaults to current account)
	//
	// http://docs.aws.amazon.com/cli/latest/reference/sqs/get_queue_url.html
	define_tag('sqs_get_queue_url', -required='queue_name', -optional='queue_owner_aws_account_id', -namespace=namespace_global);
		iterate(array('queue_name','queue_owner_aws_account_id'), local('_p'));
			local_defined(#_p) ? params->removeall('-' + #_p) & removeall(local(#_p)) & insert(('-' + #_p)=local(#_p));
		/iterate;
		return(aws('sqs', 'get-queue-url', params));
	/define_tag;

	// sqs_list_dead_letter_source_queues
	//
	// Gets a list of queue URLs which are sending to the specified dead letter queue.
	//
	// -queue_url = (url, required, also accepts a map with a "QueueURL" entry)
	//
	// http://docs.aws.amazon.com/cli/latest/reference/sqs/list_dead_letter_source_queues.html
	define_tag('sqs_list_dead_letter_source_queues', -required='queue_url', -namespace=namespace_global);
		iterate(array('queue_url'), local('_p'));
			if(local_defined(#_p));
				params->removeall('-' + #_p) & removeall(local(#_p));
				// Extract Queue URL From Map
				(#_p == 'queue_url' && local(#_p)->isa('map') && local(#_p) >> 'queueurl') ? local(#_p = local(#_p)->find('queueurl'));
				params->insert(('-' + #_p)=local(#_p));
			/if;
		/iterate;
		return(aws('sqs', 'list-dead-letter-source-queues', params));
	/define_tag;

	// sqs_list_queues
	// http://docs.aws.amazon.com/cli/latest/reference/sqs/list_queues.html
	//
	// Lists the available queues. Optional parameter allows queues to be
	// searched by prefix. Returns an array of maps with a "QueueURL" entry.
	//
	// -queue_name_prefix = (string, optional)
	//
	// http://docs.aws.amazon.com/cli/latest/reference/sqs/list-queues.html
	define_tag('sqs_list_queues', -optional='queue_name_prefix', -namespace=namespace_global);
		iterate(array('queue_name_prefix'), local('_p'));
			local_defined(#_p) ? params->removeall('-' + #_p) & removeall(local(#_p)) & insert(('-' + #_p)=local(#_p));
		/iterate;
		return(aws('sqs', 'list-queues', params));
	/define_tag;

	// sqs_receive_message
	//
	// Receives one or more messages from a queue. By default returns
	// immediately with the first waiting message, or nothing (short poll). The
	// max number of messages can be set to retrieve up to 10 messages as a
	// batch.  If the wait time is set then the tag will wait up to that number
	// of seconds for a message to arrive (long poll).  The visibility timeout
	// can be set to the number of seconds the messages should be hidden from
	// other queue listeners.  Optionally queue attributes (see
	// sqs_get_queue_attributes tag above for list) and custom message
	// attributes can be returned.
	//
	// Note: Attribute names are case sensitive.
	//
	// -queue_url = (url, required, also accepts a map with a "QueueURL" entry)
	// -max_number_of_messages = (integer, optional, defaults to 1)
	// -visibility_timeout = (integer seconds, optional, queue default)
	// -wait_time_seconds = (integer seconds, optional, defaults to 0 for short poll)
	// -attribute_names = (array of strings, optional, defaults to 'All')
	// -message_attribute_names = (array of strings, optional, defaults to 'All')
	//
	// http://docs.aws.amazon.com/cli/latest/reference/sqs/receive_message.html
	define_tag('sqs_receive_message', -required='queue_url', -optional='max_number_of_messages', -optional='wait_time_seconds', -optional='visibility_timeout', -optional='attribute_names', -optional='message_attribute_names', -namespace=namespace_global);
		iterate(array('queue_url', 'max_number_of_messages', 'wait_time_seconds', 'visibility_timeout', 'attribute_names', 'message_attribute_names'), local('_p'));
			if(local_defined(#_p));
				params->removeall('-' + #_p) & removeall(local(#_p));
				// Extract Queue URL From Map
				(#_p == 'queue_url' && local(#_p)->isa('map') && local(#_p) >> 'queueurl') ? local(#_p = local(#_p)->find('queueurl'));
				params->insert(('-' + #_p)=local(#_p));
			/if;
		/iterate;
		params !>> -attribute_names ? params->insert(-attribute_names='All');
		params !>> -message_attribute_names ? params->insert(-message_attribute_names='All');
		return(aws('sqs', 'receive-message', params));
	/define_tag;

	// sqs_remove_permission
	//
	// Removes a named permission from a queue.
	//
	// -queue_url = (url, required, also accepts a map with a "QueueURL" entry)
	// -label = (string, required, your name for this permission entry)
	//
	// http://docs.aws.amazon.com/cli/latest/reference/sqs/remove_permission.html
	define_tag('sqs_remove_permission', -required='queue_url', -required='label', -namespace=namespace_global);
		iterate(array('queue_url', 'label'), local('_p'));
			if(local_defined(#_p));
				params->removeall('-' + #_p) & removeall(local(#_p));
				// Extract Queue URL From Map
				(#_p == 'queue_url' && local(#_p)->isa('map') && local(#_p) >> 'queueurl') ? local(#_p = local(#_p)->find('queueurl'));
				params->insert(('-' + #_p)=local(#_p));
			/if;
		/iterate;
		return(aws('sqs', 'remove-permission', params));
	/define_tag;

	// sqs_send_message
	//
	// Sends a message to the queue.  The message body is a string.  See the
	// documentation for some limitations on the possible Unicode values.
	// Optional delay parameter allows the message to be hidden from the queue
	// for that number of seconds.  Optional message attributes can be used to
	// pass additional values beside the message body.
	//
	// Message attributes must be set as a map with a value and type.  See the
	// documentation for full details.  For example:
	// -message_attributes=map('myattribute'=map('StringValue'='myvalue', 'DataType'='String'))
	// -message_attributes=map('myattribute'=map('BinaryValue'='blob', 'DataType'='Binary'))
	//
	// Note: Attribute map names and data type names are case sensitive.
	//
	//
	// -queue_url = (url, required, also accepts a map with a "QueueURL" entry)
	// -message_body = (string, required)
	// -delay_seconds = (integer seconds, optional, defaults to 0)
	// -message_attributes = (map, optional)
	//
	// http://docs.aws.amazon.com/cli/latest/reference/sqs/send_message.html
	define_tag('sqs_send_message', -required='queue_url', -required='message_body', -optional='delay_seconds', -optional='message_attributes', -namespace=namespace_global);
		// Parameters
		iterate(array('queue_url', 'message_body', 'delay_seconds', 'message_attributes'), local('_p'));
			if(local_defined(#_p));
				params->removeall('-' + #_p) & removeall(local(#_p));
				// Extract Queue URL From Map
				(#_p == 'queue_url' && local(#_p)->isa('map') && local(#_p) >> 'queueurl') ? local(#_p = local(#_p)->find('queueurl'));
				params->insert(('-' + #_p)=local(#_p));
			/if;
		/iterate;
		return(aws('sqs', 'send-message', params));
	/define_tag;

	// sqs_send_message_batch
	//
	// Sends up to 10 messages.  The batch entries are specified as an array of
	// maps each containing: "ID" your identifier passed back in results,
	// "MessageBody" for the message, "DelaySeconds" the visibility delay, and
	// "MessageAttributes".
	//
	// Note: Entries map names are case sensitive.
	//
	// -queue_url = (url, required, also accepts a map with a "QueueURL" entry)
	// -entries = (map)
	//
	// http://docs.aws.amazon.com/cli/latest/reference/sqs/send_message_batch.html
	define_tag('sqs_send_message_batch', -required='queue_url', -required='entries', -namespace=namespace_global);
		// Parameters
		iterate(array('queue_url', 'entries'), local('_p'));
			if(local_defined(#_p));
				params->removeall('-' + #_p) & removeall(local(#_p));
				// Extract Queue URL From Map
				(#_p == 'queue_url' && local(#_p)->isa('map') && local(#_p) >> 'queueurl') ? local(#_p = local(#_p)->find('queueurl'));
				params->insert(('-' + #_p)=local(#_p));
			/if;
		/iterate;
		return(aws('sqs', 'send-message-batch', params));
	/define_tag;

	// sqs_set_queue_attributes
	//
	// Sets a map of attributes or settings for the queue.  The following
	// attributes are available: DelaySeconds, MaximumMessageSize,
	// MessageRetentionPeriod, Policy, ReceiveMessageWaitTimeSeconds,
	// VisibilitySeconds, RedrivePolicy.  Only the attributes which need to
	// be changed need to be passed, others will remain unchanged.
	//
	// Note: Attribute names are case sensitive.
	//
	// -queue_url = (url, required, also accepts a map with a "QueueURL" entry)
	// -attributes = (array of strings, required)
	//
	// http://docs.aws.amazon.com/cli/latest/reference/sqs/set_queue_attributes.html
	define_tag('sqs_set_queue_attributes', -required='queue_url', -required='attributes', -namespace=namespace_global);
		iterate(array('queue_url', 'attributes'), local('_p'));
			if(local_defined(#_p));
				params->removeall('-' + #_p) & removeall(local(#_p));
				// Extract Queue URL From Map
				(#_p == 'queue_url' && local(#_p)->isa('map') && local(#_p) >> 'queueurl') ? local(#_p = local(#_p)->find('queueurl'));
				params->insert(('-' + #_p)=local(#_p));
			/if;
		/iterate;
		return(aws('sqs', 'set-queue-attributes', params));
	/define_tag;

?>
