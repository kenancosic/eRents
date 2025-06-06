# eRents RabbitMQ Microservice

This microservice handles asynchronous messaging for the eRents platform, including chat messages, email notifications, booking notifications, and review notifications. It integrates with SignalR to provide real-time messaging capabilities.

## Features

- **Real-time Chat**: Processes chat messages and sends real-time notifications via SignalR
- **Email Notifications**: Sends email notifications for various events
- **Booking Notifications**: Handles booking-related notifications
- **Review Notifications**: Manages review notification delivery

## Prerequisites

1. **RabbitMQ Server**
   ```bash
   # Using Docker
   docker run -d --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3-management
   ```

2. **.NET 8.0 SDK**

3. **Running eRents WebAPI** (for SignalR integration)

## Configuration

Update `appsettings.json` with your settings:

```json
{
  "RabbitMQ": {
    "HostName": "localhost",
    "Port": 5672,
    "UserName": "guest",
    "Password": "guest"
  },
  "Email": {
    "SmtpServer": "smtp.gmail.com",
    "SmtpPort": 587,
    "SmtpUsername": "your-email@gmail.com",
    "SmtpPassword": "your-app-password",
    "FromEmail": "no-reply@erents.com",
    "FromName": "eRents Platform"
  },
  "WebApi": {
    "BaseUrl": "http://localhost:5000"
  }
}
```

## Running the Service

1. **Install dependencies**:
   ```bash
   dotnet restore
   ```

2. **Run the service**:
   ```bash
   dotnet run
   ```

## Architecture

### Message Queues

The service listens to the following RabbitMQ queues:

- **messageQueue**: Chat messages between users
- **emailQueue**: Email notifications
- **bookingQueue**: Booking-related notifications
- **reviewQueue**: Review notifications

### Message Flow

1. **Chat Messages**:
   - WebAPI receives a message via REST API or SignalR
   - Message is published to RabbitMQ `messageQueue`
   - RabbitMQMicroservice processes the message
   - Sends real-time notification via SignalR through WebAPI

2. **Email Notifications**:
   - Various services publish email messages to `emailQueue`
   - RabbitMQMicroservice sends emails via SMTP

3. **Booking/Review Notifications**:
   - Services publish notifications to respective queues
   - RabbitMQMicroservice processes and sends notifications

### SignalR Integration

The microservice communicates with the WebAPI's SignalR hub to deliver real-time notifications:

- Message notifications are sent to specific user groups
- System notifications can be broadcast to users
- Online/offline status updates are propagated

## Message Formats

### Chat Message
```json
{
  "SenderUsername": "user1",
  "RecipientUsername": "user2",
  "Subject": "Chat Message",
  "Body": "Hello, how are you?"
}
```

### Email Message
```json
{
  "Email": "user@example.com",
  "Subject": "Welcome to eRents",
  "Body": "<html>...</html>"
}
```

### Booking Notification
```json
{
  "BookingId": 123,
  "UserId": 456,
  "Message": "Your booking has been confirmed"
}
```

### Review Notification
```json
{
  "PropertyId": 789,
  "ReviewId": 321,
  "Rating": 5
}
```

## Monitoring

The service logs all activities:
- Message processing status
- Email delivery status
- SignalR notification delivery
- Error handling and retries

## Error Handling

- Failed messages are logged with full error details
- Email failures are retried with exponential backoff
- SignalR failures fallback to queued delivery

## Development

### Adding New Message Types

1. Create a new processor in `Processors/` directory
2. Implement the processor interface
3. Register the processor in `Program.cs`
4. Add consumer configuration for the new queue

### Testing

Run integration tests:
```bash
dotnet test
```

## Deployment

### Docker

```dockerfile
FROM mcr.microsoft.com/dotnet/runtime:8.0
WORKDIR /app
COPY bin/Release/net8.0/publish/ .
ENTRYPOINT ["dotnet", "eRents.RabbitMQMicroservice.dll"]
```

### Environment Variables

- `RABBITMQ__HOSTNAME`: RabbitMQ server hostname
- `RABBITMQ__PORT`: RabbitMQ server port
- `RABBITMQ__USERNAME`: RabbitMQ username
- `RABBITMQ__PASSWORD`: RabbitMQ password
- `WEBAPI__BASEURL`: WebAPI base URL for SignalR

## Troubleshooting

### Common Issues

1. **Cannot connect to RabbitMQ**:
   - Ensure RabbitMQ is running
   - Check connection settings in appsettings.json
   - Verify network connectivity

2. **SignalR notifications not working**:
   - Ensure WebAPI is running
   - Check WebAPI base URL configuration
   - Verify authentication tokens

3. **Email delivery failures**:
   - Check SMTP credentials
   - Verify email server settings
   - Check for firewall restrictions