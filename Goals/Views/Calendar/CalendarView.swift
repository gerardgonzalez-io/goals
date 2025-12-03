//
//  CalendarView.swift
//  GoalsV2
//
//  Created by Adolfo Gerard Montilla Gonzalez on 20-10-25.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    let topic: Topic
    private let topicID: Topic.ID

    @Query private var topicSessions: [StudySession]
    @State private var completionCache: [Date: Bool] = [:]
    @State private var monthOffset: Int = 0   // 0 = mes actual, -1 = mes anterior, etc.

    init(topic: Topic)
    {
        self.topic = topic
        self.topicID = topic.id

        let topicID = topic.id
        self._topicSessions = Query(filter: #Predicate<StudySession> { session in
            session.topic.id == topicID
        })
    }

    private let calendar: Calendar =
    {
        var cal = Calendar.current
        cal.firstWeekday = Calendar.current.firstWeekday
        return cal
    }()

    private let today = Date()

    // MARK: - Lógica de progreso (TUYA, intacta)

    // Primer día con sesiones para este topic (normalizado)
    private func earliestTopicDay() -> Date?
    {
        topicSessions.map(\.normalizedDay).min()
    }

    // Mostrar indicador solo para días pasados. Para hoy, solo si ya se cumplió la meta.
    private func shouldShowIndicator(on date: Date) -> Bool
    {
        // Si el tópico no tiene sesiones, no mostrar indicadores en ningún día
        if topicSessions.isEmpty { return false }

        let startOfDate = calendar.startOfDay(for: date)
        let startOfToday = calendar.startOfDay(for: today)

        if let rawFirstDay = earliestTopicDay() {
            let firstDay = calendar.startOfDay(for: rawFirstDay)
            // No mostrar nada antes de la primera sesión registrada para este topic
            if startOfDate < firstDay { return false }
        }
        // Si no hay sesiones aún (o el query aún no cargó), usar comportamiento por defecto
        if startOfDate < startOfToday { return true }
        if calendar.isDate(startOfDate, inSameDayAs: startOfToday) { return isCompleted(on: date) }
        return false
    }

    // Proveedor del estado de cumplimiento para un día concreto.
    private func isCompleted(on date: Date) -> Bool
    {
        // Cache por día normalizado para evitar recomputar
        let dayKey = calendar.startOfDay(for: date)
        if let cached = completionCache[dayKey] { return cached }

        // Filtra sesiones del mismo día (ya normalizadas por StudySession.normalizedDay)
        let sessionsForDay = topicSessions.filter { session in
            calendar.isDate(session.normalizedDay, inSameDayAs: dayKey)
        }

        guard let status = DailyStatus.compute(from: sessionsForDay) else {
            completionCache[dayKey] = false
            return false
        }

        // Día cumplido si al menos un objetivo fue cumplido
        let met = status.isMet.contains(true)
        completionCache[dayKey] = met
        return met
    }

    // MARK: - LÓGICA DE FLECHAS (copiada del otro calendario)

    /// Inicio del día de hoy
    private var todayStart: Date {
        calendar.startOfDay(for: today)
    }

    /// Primer día del mes base (mes actual) desplazado por monthOffset
    private var startOfMonth: Date
    {
        let components = calendar.dateComponents([.year, .month], from: todayStart)
        let baseMonthStart = calendar.date(from: components) ?? todayStart
        return calendar.date(byAdding: .month, value: monthOffset, to: baseMonthStart) ?? baseMonthStart
    }

    /// Título del mes (ej. "November 2025")
    private var monthTitle: String
    {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: startOfMonth)
    }

    /// ¿Podemos ir al mes siguiente? (nunca ir al futuro)
    private var canGoNextMonth: Bool {
        monthOffset < 0
    }

    private var canGoPreviousMonth: Bool {
        true // si quieres, luego lo limitamos según earliestTopicDay()
    }

    private func goToPreviousMonth() {
        monthOffset -= 1
    }

    private func goToNextMonth() {
        guard canGoNextMonth else { return }
        monthOffset += 1
    }

    // MARK: - Body

    var body: some View
    {
        ScrollView
        {
            VStack(spacing: 24)
            {
                header

                WeekdayRow(calendar: calendar)
                    .padding(.horizontal, 20)

                MonthGrid(
                    month: startOfMonth,               // ← solo este mes
                    calendar: calendar,
                    today: today,
                    isCompleted: isCompleted(on:),
                    shouldShowIndicator: shouldShowIndicator(on:)
                )
                .padding(.horizontal, 20)

                Spacer(minLength: 16)
            }
            .padding(.top, 16)
        }
        .navigationTitle(topic.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
}

// MARK: - Header con flechitas (lógica copiada)

private extension CalendarView
{
    var header: some View
    {
        // Colores de la marca
        let brandLight = Color(red: 63/255, green: 167/255, blue: 214/255) // #3FA7D6
        let brandDark  = Color(red: 29/255, green: 53/255,  blue: 87/255)  // #1D3557

        return ZStack
        {
            // Banda superior con gradiente suave de la marca
            LinearGradient(
                colors: [brandDark, brandLight],
                startPoint: .leading,
                endPoint: .trailing
            )
            .opacity(0.18)
            .ignoresSafeArea(edges: .horizontal)

            HStack(alignment: .center, spacing: 16)
            {
                // Flecha izquierda
                Button
                {
                    goToPreviousMonth()
                }
                label:
                {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Image(systemName: "chevron.left")
                                .font(.subheadline.weight(.semibold))
                        )
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .disabled(!canGoPreviousMonth)
                .opacity(canGoPreviousMonth ? 1 : 0.35)

                Spacer(minLength: 8)

                // Título de mes + subtítulo motivador
                VStack(spacing: 4)
                {
                    Text(monthTitle)
                        .font(.headline.weight(.semibold))

                    Text("See your study streak for this topic")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)

                Spacer(minLength: 8)

                // Flecha derecha
                Button
                {
                    goToNextMonth()
                }
                label:
                {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Image(systemName: "chevron.right")
                                .font(.subheadline.weight(.semibold))
                        )
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .disabled(!canGoNextMonth)
                .opacity(canGoNextMonth ? 1 : 0.35)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Fila de días de la semana

private struct WeekdayRow: View
{
    let calendar: Calendar

    var body: some View
    {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let ordered = Array(symbols[calendar.firstWeekday-1..<symbols.count]) + Array(symbols[0..<calendar.firstWeekday-1])

        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7))
        {
            ForEach(ordered, id: \.self)
            { s in
                Text(s.uppercased())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Cuadrícula del mes (TUYA, sin cambios de lógica)

private struct MonthGrid: View
{
    let month: Date
    let calendar: Calendar
    let today: Date
    let isCompleted: (Date) -> Bool
    let shouldShowIndicator: (Date) -> Bool

    var body: some View
    {
        let days = makeDays()
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 24), spacing: 0), count: 7), spacing: 12)
        {
            ForEach(days, id: \.self)
            { day in
                if let dayDate = day.date
                {
                    DayCell(date: dayDate,
                            isToday: calendar.isDate(dayDate, inSameDayAs: today),
                            inCurrentMonth: day.inCurrentMonth,
                            completed: isCompleted(dayDate),
                            showIndicator: shouldShowIndicator(dayDate))
                        .frame(height: 56)
                }
                else
                {
                    Color.clear.frame(height: 56)
                }
            }
        }
    }

    // Construye los "slots" del mes incluyendo espacios iniciales según el primer día de la semana
    private func makeDays() -> [DaySlot]
    {
        let range = calendar.range(of: .day, in: .month, for: month) ?? (1..<31)
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        let firstWeekdayIndex = calendar.component(.weekday, from: firstOfMonth)

        // Ajustar al primer día configurado en el calendario del usuario
        let leadingEmpty = (firstWeekdayIndex - calendar.firstWeekday + 7) % 7

        var result: [DaySlot] = []
        result.append(contentsOf: Array(repeating: DaySlot(date: nil, inCurrentMonth: false), count: leadingEmpty))

        for day in range
        {
            if let date = calendar.date(bySetting: .day, value: day, of: firstOfMonth)
            {
                result.append(DaySlot(date: date, inCurrentMonth: true))
            }
        }
        // Rellenar hasta múltiplo de 7 para cuadrícula completa
        while result.count % 7 != 0
        {
            result.append(DaySlot(date: nil, inCurrentMonth: false))
        }
        return result
    }

    struct DaySlot: Hashable
    {
        let date: Date?
        let inCurrentMonth: Bool
    }
}

// MARK: - Celda de día (igual que tu versión original de Goals)

private struct DayCell: View
{
    let date: Date
    let isToday: Bool
    let inCurrentMonth: Bool
    let completed: Bool
    let showIndicator: Bool

    var body: some View
    {
        VStack(spacing: 6)
        {
            Text(dayNumber)
                .font(.body.weight(isToday ? .semibold : .regular))
                .foregroundStyle(inCurrentMonth ? Color.primary : Color.secondary.opacity(0.3))
                .frame(maxWidth: .infinity)
                .overlay(alignment: .topTrailing)
                {
                    if isToday
                    {
                        Circle()
                            .strokeBorder(Color.accentColor.opacity(0.6), lineWidth: 1)
                            .frame(width: 22, height: 22)
                            .opacity(0) // marcador visual ligero si lo necesitas
                    }
                }

            // Indicador de cumplimiento (reservar espacio fijo para evitar desalineaciones)
            ZStack
            {
                if showIndicator
                {
                    Image(systemName: completed ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(completed ? Color.green : Color.red, .tint.opacity(0.2))
                        .font(.system(size: 28, weight: .semibold))
                        .opacity(inCurrentMonth ? 1 : 0.3)
                        .accessibilityLabel(completed ? "Completado" : "No completado")
                }
                else
                {
                    // Placeholder invisible del mismo tamaño para mantener el alto
                    Image(systemName: "circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .opacity(0)
                        .accessibilityHidden(true)
                }
            }
            .frame(height: 28)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var dayNumber: String
    {
        let comps = Calendar.current.dateComponents([.day], from: date)
        return String(comps.day ?? 0)
    }

    private var accessibilityText: String
    {
        let df = DateFormatter()
        df.dateStyle = .full
        let base = df.string(from: date)
        if showIndicator
        {
            return completed ? "\(base), objetivo completado" : "\(base), objetivo no completado"
        }
        else
        {
            return base
        }
    }
}

// MARK: - Blur helper

private struct VisualEffectBlur: UIViewRepresentable
{
    let style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView
    {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

#Preview("Dark")
{
    CalendarView(topic: SampleData.shared.topic)
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.dark)
}

#Preview("Light")
{
    CalendarView(topic: SampleData.shared.topic)
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.light)
}
