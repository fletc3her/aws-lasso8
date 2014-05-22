aws-lasso
=========

AWS SDK Implementation for Lasso 8.x

Important - This implementation relies on the AWS CLI interface available from Amazon.  Consult the user guide for installation instructions.  Python 2.6.3 is required so older Linux distributions will need to have Python upgraded.

http://aws.amazon.com/documentation/cli/


Authentication
---------

Every AWS call requires an Access Key ID and a Secret Access Key.  These are issued in the IAM section of the AWS console.  You should create a user specific for your web server or for each individual site so that you can fine tune the permissions granted.

https://aws.amazon.com/documentation/iam/

1 - Open https://console.aws.amazon.com/iam/home and create a user for your web server.

2 - Copy the credentials provided.  This is the only time the Secret Access Key will be provided.

3 - Select the user, Permissions tab, and click Attach User Policy.  This wizard will allow you to control what services the user has access to.  Ideally provide read-only access when possible and full access only to necessary services.

There are three ways to provide the access keys to the Lasso SDK implementation.

- If you are using a dedicated server for one Lasso site then the access keys can be specified using the "aws configure" tool on the command line.  This will allow both Lasso and command line users free access to the services allowed for the user.

- You can specify the access keys at the top of a page using the [aws_accesskeyid(key)] and [aws_secretaccesskey(secret)] tags.  All other AWS calls on the page will use these values.  If you place these tags in LassoStartup the access keys will be available globally.

- You can specify the access keys on individual tag calls.  Particularly useful if you need to use different access keys for different actions.
