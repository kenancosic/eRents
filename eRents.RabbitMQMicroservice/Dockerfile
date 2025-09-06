# Simple Dockerfile for RabbitMQ Microservice
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["eRents.RabbitMQMicroservice.csproj", "./"]
RUN dotnet restore "./eRents.RabbitMQMicroservice.csproj"
COPY . .
RUN dotnet build "eRents.RabbitMQMicroservice.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "eRents.RabbitMQMicroservice.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "eRents.RabbitMQMicroservice.dll"]