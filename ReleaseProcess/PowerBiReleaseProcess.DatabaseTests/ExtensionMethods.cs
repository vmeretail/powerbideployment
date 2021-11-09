namespace PowerBiReleaseProcess.DatabaseTests
{
    public static class ExtensionMethods
    {
        #region Methods

        /// <summary>
        /// Asserts the can be enumerated.
        /// </summary>
        /// <param name="readModelContext">The read model context.</param>
        /// <param name="view">The view.</param>
        /// <exception cref="Exception">Error occurred trying to enumerate view of type [{view.Name}]. Error was {exception}</exception>
        //public static void AssertCanBeEnumerated(this ReadModelContext readModelContext,
        //                                         Type view)
        //{
        //    try
        //    {
        //        // Get the generic method definition for DbSet<>
        //        MethodInfo dbSetMethodInfo = typeof(ReadModelContext).GetMethods().First(p => p.Name == "Set" && p.ContainsGenericParameters);

        //        // Build a version of DbSet<> with the required type.
        //        dbSetMethodInfo = dbSetMethodInfo.MakeGenericMethod(view);

        //        // Invoke DbSet<> and get the result as IQueryable
        //        IQueryable dbSetResult = dbSetMethodInfo.Invoke(readModelContext, null) as IQueryable;

        //        // Get the generic method definition for Enumerable<T>.ToList()
        //        MethodInfo genericToListInfo = typeof(Enumerable).GetMethod("ToList").MakeGenericMethod(dbSetResult.ElementType);

        //        // Invoke ToList()
        //        IList list = (IList)genericToListInfo.Invoke(null, new[] {dbSetResult});
        //    }
        //    catch(Exception exception)
        //    {
        //        throw new Exception($"Error occurred trying to enumerate view of type [{view.Name}]. Error was {exception}");
        //    }
        //}

        #endregion
    }
}