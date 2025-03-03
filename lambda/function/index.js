const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
  const { DynamoDBDocumentClient, UpdateCommand } = require('@aws-sdk/lib-dynamodb');

  const client = new DynamoDBClient({});
  const dynamoDB = DynamoDBDocumentClient.from(client);

  exports.handler = async (event) => {
      const params = {
          TableName: process.env.TABLE_NAME,
          Key: {
              id: 'visitors'
          },
          UpdateExpression: 'SET #count = if_not_exists(#count, :start) + :increment',
          ExpressionAttributeNames: {
              '#count': 'count'
          },
          ExpressionAttributeValues: {
              ':increment': 1,
              ':start': 0
          },
          ReturnValues: 'UPDATED_NEW'
      };

      try {
          const data = await dynamoDB.send(new UpdateCommand(params));

          // Set proper CORS headers
          const response = {
              statusCode: 200,
              headers: {
                  'Access-Control-Allow-Origin': '*',
                  'Access-Control-Allow-Methods': 'GET, OPTIONS',
                  'Access-Control-Allow-Headers': 'Content-Type'
              },
              body: JSON.stringify({ count: data.Attributes.count })
          };

          return response;
      } catch (error) {
          console.error('Error updating counter:', error);
          return {
              statusCode: 500,
              headers: {
                  'Access-Control-Allow-Origin': '*'
              },
              body: JSON.stringify({ error: 'Failed to update visitor count' })
          };
      }
  };