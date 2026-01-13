# Simple Dockerfile for RabbitMQ Microservice
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
# Copy the solution file and dependencies first
COPY ["eRents.sln", "./"]
COPY ["eRents.RabbitMQMicroservice/eRents.RabbitMQMicroservice.csproj", "eRents.RabbitMQMicroservice/"]
COPY ["eRents.Domain/eRents.Domain.csproj", "eRents.Domain/"]
COPY ["eRents.Shared/eRents.Shared.csproj", "eRents.Shared/"]
RUN dotnet restore "eRents.RabbitMQMicroservice/eRents.RabbitMQMicroservice.csproj"
# Copy only necessary source files, exclude mobile apps, docs, git
COPY ["eRents.RabbitMQMicroservice/", "eRents.RabbitMQMicroservice/"]
COPY ["eRents.Domain/", "eRents.Domain/"]
COPY ["eRents.Shared/", "eRents.Shared/"]
RUN dotnet build "eRents.RabbitMQMicroservice/eRents.RabbitMQMicroservice.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "eRents.RabbitMQMicroservice/eRents.RabbitMQMicroservice.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "eRents.RabbitMQMicroservice.dll"]