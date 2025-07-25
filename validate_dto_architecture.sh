#!/bin/bash

echo "=========================================="
echo "🔍 DTO Architecture Validation Report"
echo "=========================================="
echo "Generated: $(date)"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to count violations
count_violations() {
    local feature_path="$1"
    find "$feature_path" -name "*.cs" -exec grep -l "using eRents.Shared.DTO" {} \; 2>/dev/null | wc -l
}

# Function to check if feature has DTOs
has_dtos() {
    local feature_path="$1"
    [ -d "$feature_path/DTOs" ] && echo "YES" || echo "NO"
}

# Function to list DTO files in feature
list_dto_files() {
    local feature_path="$1"
    if [ -d "$feature_path/DTOs" ]; then
        ls "$feature_path/DTOs/"*.cs 2>/dev/null | wc -l
    else
        echo "0"
    fi
}

echo -e "${BLUE}📊 Current State Analysis${NC}"
echo "----------------------------------------"

# Count DTOs in shared vs features
shared_count=$(find eRents.Shared/DTO -name "*.cs" 2>/dev/null | wc -l)
feature_count=$(find eRents.Features/*/DTOs -name "*.cs" 2>/dev/null | wc -l)

echo "Current Distribution:"
echo "  📁 eRents.Shared/DTO: $shared_count files"
echo "  📁 Feature DTOs: $feature_count files"
echo ""

echo -e "${BLUE}🎯 Feature Compliance Status${NC}"
echo "----------------------------------------"

total_features=0
compliant_features=0

for feature in eRents.Features/*/; do
    feature_name=$(basename "$feature")
    if [ "$feature_name" != "Shared" ]; then
        total_features=$((total_features + 1))
        
        has_dtos_result=$(has_dtos "$feature")
        violations=$(count_violations "$feature")
        dto_count=$(list_dto_files "$feature")
        
        if [ $violations -eq 0 ] && [ "$has_dtos_result" = "YES" ] && [ $dto_count -gt 0 ]; then
            status="${GREEN}✅ COMPLIANT${NC}"
            compliant_features=$((compliant_features + 1))
        elif [ $violations -eq 0 ] && [ "$has_dtos_result" = "NO" ]; then
            status="${YELLOW}⚠️  NO DTOs${NC}"
        else
            status="${RED}❌ VIOLATIONS${NC}"
        fi
        
        echo -e "  $feature_name: $status (DTOs: $has_dtos_result, Files: $dto_count, Violations: $violations)"
    fi
done

echo ""
echo -e "${BLUE}📈 Overall Progress${NC}"
echo "----------------------------------------"
compliance_percentage=$((compliant_features * 100 / total_features))
echo "Compliant Features: $compliant_features / $total_features ($compliance_percentage%)"

echo ""
echo -e "${BLUE}🚨 Detailed Violation Analysis${NC}"
echo "----------------------------------------"

total_violations=0
for feature in eRents.Features/*/; do
    feature_name=$(basename "$feature")
    if [ "$feature_name" != "Shared" ]; then
        violations=$(count_violations "$feature")
        if [ $violations -gt 0 ]; then
            total_violations=$((total_violations + violations))
            echo -e "${RED}❌ $feature_name: $violations violations${NC}"
            
            # List specific files with violations
            find "$feature" -name "*.cs" -exec grep -l "using eRents.Shared.DTO" {} \; 2>/dev/null | while read file; do
                relative_file=$(echo "$file" | sed "s|^eRents.Features/||")
                echo "     • $relative_file"
            done
        fi
    fi
done

if [ $total_violations -eq 0 ]; then
    echo -e "${GREEN}✅ No violations found!${NC}"
else
    echo -e "${RED}Total violations across all features: $total_violations${NC}"
fi

echo ""
echo -e "${BLUE}📋 Next Steps${NC}"
echo "----------------------------------------"

if [ $compliance_percentage -eq 100 ]; then
    echo -e "${GREEN}🎉 All features are compliant! Time for final cleanup.${NC}"
else
    echo "Priority order for fixing violations:"
    echo "1. 🔧 BookingManagement (most critical)"
    echo "2. 👥 UserManagement (core functionality)"
    echo "3. 🔧 MaintenanceManagement"
    echo "4. 💰 FinancialManagement"
    echo "5. 🏠 RentalManagement"
    echo "6. 👤 TenantManagement"
    echo "7. ⭐ ReviewManagement"
    echo ""
    echo "Run this script after each feature migration to track progress."
fi

echo ""
echo -e "${BLUE}🔗 Migration Commands${NC}"
echo "----------------------------------------"
echo "To migrate a feature manually:"
echo "1. Create feature-specific DTOs"
echo "2. Update service interfaces"
echo "3. Update implementations"
echo "4. Update controllers"
echo "5. Run: ./validate_dto_architecture.sh"
echo ""
echo "For automated migration, use the comprehensive script:"
echo "📋 See: MODULAR_ARCHITECTURE_MIGRATION_SCRIPT.md"

echo ""
echo "==========================================" 