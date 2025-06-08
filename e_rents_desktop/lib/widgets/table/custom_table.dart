// ═══════════════════════════════════════════════════════════════════════════════
// UNIVERSAL TABLE SYSTEM - Complete modular table solution
// ═══════════════════════════════════════════════════════════════════════════════
//
// This file provides everything needed for data tables through modular architecture:
// - Query parameters and pagination (core/)
// - Column configuration and filtering (core/)
// - Data providers and table widgets (providers/, universal_table_widget.dart)
// - Helper utilities for common cell types (utils/)
// - Factory methods for quick table creation (utils/)
//
// Usage Examples:
// 1. Simple table: UniversalTable.create(...)
// 2. Custom provider: extend BaseTableProvider or TableProvider
// 3. Full configuration: UniversalTableWidget with UniversalTableConfig
//
// ═══════════════════════════════════════════════════════════════════════════════

// Export all core components
export 'core/table_types.dart';
export 'core/table_query.dart';
export 'core/table_filters.dart';
export 'core/table_columns.dart';

// Export provider system
export 'providers/base_table_provider.dart';
export 'providers/table_provider.dart';

// Export configuration system
export 'config/table_config.dart';

// Export main table widget
export 'universal_table_widget.dart';

// Export utilities (the main API like ImageUtils)
export 'utils/table_helpers.dart';
